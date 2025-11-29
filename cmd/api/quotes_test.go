package main

import (
    "bytes"
    "net/http"
    "net/http/httptest"
    "testing"
    "io"
    "log/slog"
    "github.com/aiycoleman/Study-Mate/internal/data"
)

func newTestAppQuotes() *application {
    logger := slog.New(slog.NewTextHandler(io.Discard, nil))
    return &application{logger: logger}
}

func TestCreateQuotesHandler_BadJSON(t *testing.T) {
    app := newTestAppQuotes()
    req := httptest.NewRequest(http.MethodPost, "/v1/quotes", bytes.NewBufferString("{bad json"))
    // set an authenticated user in context to avoid panic
    usr := &data.User{ID: 1, Username: "testuser", Email: "t@example.com"}
    req = app.contextSetUser(req, usr)
    rr := httptest.NewRecorder()

    app.createQuotesHandler(rr, req)

    if rr.Code != http.StatusBadRequest {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusBadRequest, rr.Code, rr.Body.String())
    }
}

func TestCreateQuotesHandler_InvalidData(t *testing.T) {
    app := newTestAppQuotes()
    payload := `{"content":""}`
    req := httptest.NewRequest(http.MethodPost, "/v1/quotes", bytes.NewBufferString(payload))
    req.Header.Set("Content-Type", "application/json")
    // set an authenticated user in context to avoid panic
    usr := &data.User{ID: 1, Username: "testuser", Email: "t@example.com"}
    req = app.contextSetUser(req, usr)
    rr := httptest.NewRecorder()

    app.createQuotesHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}

func TestDisplayQuotesHandler_InvalidID(t *testing.T) {
    app := newTestAppQuotes()
    req := httptest.NewRequest(http.MethodGet, "/v1/quotes/", nil)
    rr := httptest.NewRecorder()

    app.displayQuotesHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestUpdateQuotesHandler_InvalidID(t *testing.T) {
    app := newTestAppQuotes()
    req := httptest.NewRequest(http.MethodPatch, "/v1/quotes/", nil)
    rr := httptest.NewRecorder()

    app.updateQuotesHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestDeleteQuotesHandler_InvalidID(t *testing.T) {
    app := newTestAppQuotes()
    req := httptest.NewRequest(http.MethodDelete, "/v1/quotes/", nil)
    rr := httptest.NewRecorder()

    app.deleteQuotesHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestListQuotesHandler_InvalidPageParam(t *testing.T) {
    app := newTestAppQuotes()
    req := httptest.NewRequest(http.MethodGet, "/v1/quotes?page=notint", nil)
    rr := httptest.NewRecorder()

    app.listQuotesHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}