// Filename : cmd/api/users.go
package main

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/aiycoleman/Study-Mate/internal/data"
	"github.com/aiycoleman/Study-Mate/internal/validator"
)

func (app *application) createQuotesHandler(w http.ResponseWriter, r *http.Request) {

	user := app.contextGetUser(r)
	if user.IsAnonymous() {
		app.authenticationRequiredResponse(w, r)
		return
	}
	var incomingData struct {
		Content string `json:"content"`
	}

	err := app.readJSON(w, r, &incomingData)
	if err != nil {
		app.badRequestResponse(w, r, err)
		return
	}

	quote := &data.Quote{
		UserID:  user.ID,
		Content: incomingData.Content,
	}

	// Validate the quote data
	v := validator.New()
	data.ValidateQuote(v, quote)
	if !v.Valid() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}

	// Insert the quote into the database
	err = app.quoteModel.Insert(quote)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	headers := make(http.Header)
	headers.Set("Location", fmt.Sprintf("/v1/quotes/%d", quote.ID))

	// Senda JSON response with 201 Created status
	data := envelope{"quote": quote}
	err = app.writeJSON(w, http.StatusCreated, data, headers)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Display the users quote based on ID
func (app *application) displayQuotesHandler(w http.ResponseWriter, r *http.Request) {
	// get id from the url
	id, err := app.readIDParam(r)
	if err != nil {
		app.notFoundResponse(w, r)
		return
	}

	quote, err := app.quoteModel.Get(id)
	if err != nil {
		switch {
		case errors.Is(err, data.ErrRecordNotFound):
			app.notFoundResponse(w, r)
		default:
			app.serverErrorResponse(w, r, err)
		}
		return
	}

	// send the quote as json response
	data := envelope{"quote": quote}
	err = app.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}

// Listing all quotes (with pagination)
func (app *application) listQuotesHandler(w http.ResponseWriter, r *http.Request) {
	var queryParametersData struct {
		Content string
		data.Filters
	}

	// get the query parameters from the url
	queryParameters := r.URL.Query()

	// load the query parameters into the struct
	queryParametersData.Content = app.getSingleQueryParameter(queryParameters, "content", "")

	v := validator.New()
	queryParametersData.Filters.Page = app.getSingleIntegerParameter(queryParameters, "page", 1, v)
	queryParametersData.Filters.PageSize = app.getSingleIntegerParameter(queryParameters, "page_size", 15, v)
	queryParametersData.Filters.Sort = app.getSingleQueryParameter(queryParameters, "sort", "id")
	queryParametersData.Filters.SortSafeList = []string{"id", "user_id", "content", "-id", "-user_id", "-content"}

	// Check if the filters are valid
	data.ValidateFilters(v, queryParametersData.Filters)
	if !v.IsEmpty() {
		app.failedValidationResponse(w, r, v.Errors)
		return
	}

	// get the list of courses from the database
	quotes, metadata, err := app.quoteModel.GetAll(queryParametersData.Content, queryParametersData.Filters)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}

	// send the quotes as json response
	data := envelope{
		"quotes":    quotes,
		"@metadata": metadata,
	}
	err = app.writeJSON(w, http.StatusOK, data, nil)
	if err != nil {
		app.serverErrorResponse(w, r, err)
		return
	}
}
