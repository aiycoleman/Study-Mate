// Filename: cmd/api/goals.go
package main

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/aiycoleman/Study-Mate/internal/data"
	"github.com/aiycoleman/Study-Mate/internal/validator"
)

func (app *application) createGoalsHandler(w http.ResponseWriter, r *http.Request) {
	user := app.contextGetUser(r)
	if user.IsAnonymous() {
		app.authenticationRequiredResponse(w, r)
		return
	}

	var incomingData struct {
		GoalText   string    `json:"goal_text"`
		TargetDate time.Time `json:"target_date"`
	}

	err := app.readJSON(w, r, &incomingData)
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	goal := &data.Goal{
		UserID:     user.ID,
		GoalText:   incomingData.GoalText,
		TargetDate: incomingData.TargetDate,
	}

	// Validate the goal data
	v := validator.New()
	data.ValidateGoal(v, goal)
	if !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Insert the goal into the database
	err = app.goalModel.Insert(goal)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/goals/%d", goal.ID))

	// Send a JSON response with 201 Created status
	data := envelope{"goal": goal}
	err = app.writeJSON(w, http.StatusCreated, data, headers)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Display goal based on ID
func (app *application) displayGoalsHandler(w http.ResponseWriter, r *http.Request) {
	goalID, err := app.readIDParam(r)
	if err != nil {
		app.notFoundResponse(w, r)
		return
	}

	goal, err := app.goalModel.Get(goalID)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}

	// Send the goal data in a JSON response
	responseData := envelope{"goal": goal}
	err = app.writeJSON(w, http.StatusOK, responseData, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Listing all goals (with pagination)
func (app *application) listGoalsHandler(w http.ResponseWriter, r *http.Request) {
	var queryParametersData struct {
		GoalText    string
		TargetDate  time.Time
		IsCompleted bool
		data.Filters
	}

	queryParameters := r.URL.Query()

	// load the query parameters into the struct
	queryParametersData.GoalText = app.getSingleQueryParameter(queryParameters, "goal_text", "")
	targetDateStr := app.getSingleQueryParameter(queryParameters, "target_date", "")
	if targetDateStr != "" {
		targetDate, err := time.Parse("2006-01-02", targetDateStr) // or whatever format you use
		if err != nil {
			app.failedValidationResponse(w, r, map[string]string{"target_date": "invalid date format"})
			return
		}
		queryParametersData.TargetDate = targetDate
	}
	isCompletedStr := app.getSingleQueryParameter(queryParameters, "is_completed", "")
	if isCompletedStr != "" {
		if isCompletedStr == "true" {
			queryParametersData.IsCompleted = true
		} else if isCompletedStr == "false" {
			queryParametersData.IsCompleted = false
		} else {
			app.failedValidationResponse(w, r, map[string]string{"is_completed": "must be 'true' or 'false'"})
			return
		}
	}
	// Additional query parameters can be processed here

	v := validator.New()
	queryParametersData.Filters.Page = app.getSingleIntegerParameter(queryParameters, "page", 1, v)
	queryParametersData.Filters.PageSize = app.getSingleIntegerParameter(queryParameters, "page_size", 15, v)
	queryParametersData.Filters.Sort = app.getSingleQueryParameter(queryParameters, "sort", "goal_id")
	queryParametersData.Filters.SortSafeList = []string{"goal_id", "user_id", "goal_text", "target_date", "is_completed", "-goal_id", "-user_id", "-goal_text", "-target_date", "-is_completed"}
	// Validate the filters
	data.ValidateFilters(v, queryParametersData.Filters)
	if !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}
	// Get the list of goals from the database
	goals, metadata, err := app.goalModel.GetAll(queryParametersData.GoalText, queryParametersData.TargetDate, queryParametersData.IsCompleted, queryParametersData.Filters)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	// Send the goals and metadata in a JSON response
	responseData := envelope{
		"metadata": metadata,
		"goals":    goals,
	}
	err = app.writeJSON(w, http.StatusOK, responseData, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}
