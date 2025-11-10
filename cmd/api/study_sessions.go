// Filename: cmd/api/routes.go

package main

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/aiycoleman/Study-Mate/internal/data"
	"github.com/aiycoleman/Study-Mate/internal/validator"
)

func (app *application) createStudySessionHandler(w http.ResponseWriter, r *http.Request) {
	user := app.contextGetUser(r)
	if user.IsAnonymous() {
		app.authenticationRequiredResponse(w, r)
		return
	}

	var incomingData struct {
		Title       string    `json:"title"`
		Description string    `json:"description"`
		Subject     string    `json:"subject"`
		StartTime   time.Time `json:"start_time"`
		EndTime     time.Time `json:"end_time"`
		IsCompleted bool      `json:"is_completed"`
	}

	err := app.readJSON(w, r, &incomingData)
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	studySession := &data.StudySession{
		UserID:      user.ID,
		Title:       incomingData.Title,
		Description: incomingData.Description,
		Subject:     incomingData.Subject,
		StartTime:   incomingData.StartTime,
		EndTime:     incomingData.EndTime,
		IsCompleted: incomingData.IsCompleted,
	}

	// Validate the study session data
	v := validator.New()
	data.ValidateStudySession(v, studySession)
	if !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Insert the study session into the database
	err = app.studysessionModel.Insert(studySession)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/study-sessions/%d", studySession.ID))

	// Send a JSON response with 201 Created status
	data := envelope{"study_session": studySession}
	err = app.writeJSON(w, http.StatusCreated, data, headers)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Display study session based on ID
func (app *application) displayStudySessionHandler(w http.ResponseWriter, r *http.Request) {
	// Get id from the url
	studySessionID, err := app.readIDParam(r)
	if err != nil {
		app.notFoundResponse(w, r)
		return
	}

	studySession, err := app.studysessionModel.Get(studySessionID)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}

	// Send the study session as JSON response
	data := envelope{"study_session": studySession}
	err = app.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Listing all study sessions (with pagination)
func (app *application) listStudySessionsHandler(w http.ResponseWriter, r *http.Request) {
	var queryParametersData struct {
		Title       string
		Description string
		Subject     string
		IsCompleted *bool
		data.Filters
	}

	// get the query parameters from the url
	queryParameters := r.URL.Query()

	// load the query parameters into the struct
	queryParametersData.Title = app.getSingleQueryParameter(queryParameters, "title", "")
	queryParametersData.Subject = app.getSingleQueryParameter(queryParameters, "subject", "")

	isCompletedStr := app.getSingleQueryParameter(queryParameters, "is_completed", "")
	if isCompletedStr != "" {
		val := isCompletedStr == "true"
		queryParametersData.IsCompleted = &val
	}

	v := validator.New()
	queryParametersData.Filters.Page = app.getSingleIntegerParameter(queryParameters, "page", 1, v)
	queryParametersData.Filters.PageSize = app.getSingleIntegerParameter(queryParameters, "page_size", 20, v)
	queryParametersData.Filters.Sort = app.getSingleQueryParameter(queryParameters, "sort", "created_at")
	queryParametersData.Filters.SortSafeList = []string{"session_id", "title", "subject", "is_completed", "created_at"}

	// Validate the filters
	data.ValidateFilters(v, queryParametersData.Filters)
	if !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Get the study sessions from the database
	studySessions, metadata, err := app.studysessionModel.GetAll(queryParametersData.Title, queryParametersData.Subject, queryParametersData.IsCompleted, queryParametersData.Filters)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	// Send the study sessions as JSON response
	data := envelope{
		"study_sessions": studySessions,
		"@metadata":      metadata,
	}
	err = app.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

}

// Update study session based on ID
func (app *application) updateStudySessionHandler(w http.ResponseWriter, r *http.Request) {
	studySessionID, err := app.readIDParam(r)
	if err != nil {
		app.notFoundResponse(w, r)
		return
	}
	// Fetch the existing study session
	studySession, err := app.studysessionModel.Get(studySessionID)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}

	var incomingData struct {
		Title       *string    `json:"title"`
		Description *string    `json:"description"`
		Subject     *string    `json:"subject"`
		StartTime   *time.Time `json:"start_time"`
		EndTime     *time.Time `json:"end_time"`
		IsCompleted *bool      `json:"is_completed"`
	}

	err = app.readJSON(w, r, &incomingData)
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	// Update fields if they are provided
	if incomingData.Title != nil {
		studySession.Title = *incomingData.Title
	}
	if incomingData.Description != nil {
		studySession.Description = *incomingData.Description
	}
	if incomingData.Subject != nil {
		studySession.Subject = *incomingData.Subject
	}
	if incomingData.StartTime != nil {
		studySession.StartTime = *incomingData.StartTime
	}
	if incomingData.EndTime != nil {
		studySession.EndTime = *incomingData.EndTime
	}
	if incomingData.IsCompleted != nil {
		studySession.IsCompleted = *incomingData.IsCompleted
	}

	// Validate the updated study session data
	v := validator.New()
	data.ValidateStudySession(v, studySession)
	if !v.IsEmpty() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Update the study session in the database
	err = app.studysessionModel.Update(studySession)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	// Send the updated study session as JSON response
	data := envelope{"study_session": studySession}
	err = app.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Delete study session based on ID
func (app *application) deleteStudySessionHandler(w http.ResponseWriter, r *http.Request) {
	studySessionID, err := app.readIDParam(r)
	if err != nil {
		app.notFoundResponse(w, r)
		return
	}

	err = app.studysessionModel.Delete(studySessionID)
	if err != nil {
		switch {
		case err == data.ErrRecordNotFound:
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}

	err = app.writeJSON(w, http.StatusOK, envelope{"message": "study session successfully deleted"}, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}
