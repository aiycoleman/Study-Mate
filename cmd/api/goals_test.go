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

func newTestAppGoals() *application {
    logger := slog.New(slog.NewTextHandler(io.Discard, nil))
    return &application{logger: logger}
}

func TestCreateGoalsHandler_BadJSON(t *testing.T) {
    app := newTestAppGoals()
    req := httptest.NewRequest(http.MethodPost, "/v1/goals", bytes.NewBufferString("{bad json"))
    // set an authenticated user in context to avoid panic
    usr := &data.User{ID: 1, Username: "testuser", Email: "t@example.com"}
    req = app.contextSetUser(req, usr)
    rr := httptest.NewRecorder()

    app.createGoalsHandler(rr, req)

    if rr.Code != http.StatusBadRequest {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusBadRequest, rr.Code, rr.Body.String())
    }
}

func TestCreateGoalsHandler_InvalidData(t *testing.T) {
    app := newTestAppGoals()
    // missing goal_text should be invalid; omit target_date so it unmarshals as zero value
    payload := `{"goal_text":""}`
    req := httptest.NewRequest(http.MethodPost, "/v1/goals", bytes.NewBufferString(payload))
    req.Header.Set("Content-Type", "application/json")
    // set an authenticated user in context to avoid panic
    usr := &data.User{ID: 1, Username: "testuser", Email: "t@example.com"}
    req = app.contextSetUser(req, usr)
    rr := httptest.NewRecorder()

    app.createGoalsHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}

func TestDisplayGoalsHandler_InvalidID(t *testing.T) {
    app := newTestAppGoals()
    req := httptest.NewRequest(http.MethodGet, "/v1/goals/", nil)
    rr := httptest.NewRecorder()

    app.displayGoalsHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestUpdateGoalsHandler_InvalidID(t *testing.T) {
    app := newTestAppGoals()
    req := httptest.NewRequest(http.MethodPatch, "/v1/goals/", nil)
    rr := httptest.NewRecorder()

    app.updateGoalsHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestDeleteGoalsHandler_InvalidID(t *testing.T) {
    app := newTestAppGoals()
    req := httptest.NewRequest(http.MethodDelete, "/v1/goals/", nil)
    rr := httptest.NewRecorder()

    app.deleteGoalsHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestListGoalsHandler_InvalidPageParam(t *testing.T) {
    app := newTestAppGoals()
    req := httptest.NewRequest(http.MethodGet, "/v1/goals?page=notint", nil)
    rr := httptest.NewRecorder()

    app.listGoalsHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}