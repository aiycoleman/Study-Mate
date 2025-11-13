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

func newTestAppSessions() *application {
    logger := slog.New(slog.NewTextHandler(io.Discard, nil))
    return &application{logger: logger}
}

func TestCreateStudySessionHandler_BadJSON(t *testing.T) {
    app := newTestAppSessions()
    req := httptest.NewRequest(http.MethodPost, "/v1/study-sessions", bytes.NewBufferString("{bad json"))
    // set an authenticated user in context to avoid panic
    usr := &data.User{ID: 1, Username: "testuser", Email: "t@example.com"}
    req = app.contextSetUser(req, usr)
    rr := httptest.NewRecorder()

    app.createStudySessionHandler(rr, req)

    if rr.Code != http.StatusBadRequest {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusBadRequest, rr.Code, rr.Body.String())
    }
}

func TestCreateStudySessionHandler_InvalidData(t *testing.T) {
    app := newTestAppSessions()
    // missing title should be invalid; omit time fields so they unmarshal as zero values
    payload := `{"title":"","description":"","subject":""}`
    req := httptest.NewRequest(http.MethodPost, "/v1/study-sessions", bytes.NewBufferString(payload))
    req.Header.Set("Content-Type", "application/json")
    // set an authenticated user in context to avoid panic
    usr := &data.User{ID: 1, Username: "testuser", Email: "t@example.com"}
    req = app.contextSetUser(req, usr)
    rr := httptest.NewRecorder()

    app.createStudySessionHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}

func TestDisplayStudySessionHandler_InvalidID(t *testing.T) {
    app := newTestAppSessions()
    req := httptest.NewRequest(http.MethodGet, "/v1/study-sessions/", nil)
    rr := httptest.NewRecorder()

    app.displayStudySessionHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestUpdateStudySessionHandler_InvalidID(t *testing.T) {
    app := newTestAppSessions()
    req := httptest.NewRequest(http.MethodPatch, "/v1/study-sessions/", nil)
    rr := httptest.NewRecorder()

    app.updateStudySessionHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestDeleteStudySessionHandler_InvalidID(t *testing.T) {
    app := newTestAppSessions()
    req := httptest.NewRequest(http.MethodDelete, "/v1/study-sessions/", nil)
    rr := httptest.NewRecorder()

    app.deleteStudySessionHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestListStudySessionsHandler_InvalidPageParam(t *testing.T) {
    app := newTestAppSessions()
    req := httptest.NewRequest(http.MethodGet, "/v1/study-sessions?page=notint", nil)
    rr := httptest.NewRecorder()

    app.listStudySessionsHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}