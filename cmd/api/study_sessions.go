// Filename: cmd/api/routes.go

package main

import (
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
