package main

import (
    "bytes"
    "net/http"
    "net/http/httptest"
    "testing"
    "io"
    "log/slog"
)

var testApp *application

func newTestApp() *application {
    if testApp != nil {
        return testApp
    }
    logger := slog.New(slog.NewTextHandler(io.Discard, nil))
    testApp = &application{logger: logger}
    return testApp
}

func TestRegisterUserHandler_BadJSON(t *testing.T) {
    app := newTestApp()
    req := httptest.NewRequest(http.MethodPost, "/v1/users/register", bytes.NewBufferString("{bad json"))
    rr := httptest.NewRecorder()

    app.registerUserHandler(rr, req)

    if rr.Code != http.StatusBadRequest {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusBadRequest, rr.Code, rr.Body.String())
    }
}

func TestRegisterUserHandler_InvalidData(t *testing.T) {
    app := newTestApp()
    payload := `{"username":"","email":"invalid","password":"short"}`
    req := httptest.NewRequest(http.MethodPost, "/v1/users/register", bytes.NewBufferString(payload))
    req.Header.Set("Content-Type", "application/json")
    rr := httptest.NewRecorder()

    app.registerUserHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}

func TestActivateUserHandler_InvalidToken(t *testing.T) {
    app := newTestApp()
    payload := `{"token":""}`
    req := httptest.NewRequest(http.MethodPost, "/v1/users/activated", bytes.NewBufferString(payload))
    req.Header.Set("Content-Type", "application/json")
    rr := httptest.NewRecorder()

    app.activateUserHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}

func TestListUsersHandler_InvalidQueryParam(t *testing.T) {
    app := newTestApp()
    req := httptest.NewRequest(http.MethodGet, "/v1/users?page=notint", nil)
    rr := httptest.NewRecorder()

    app.listUsersHandler(rr, req)

    if rr.Code != http.StatusUnprocessableEntity {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusUnprocessableEntity, rr.Code, rr.Body.String())
    }
}

func TestUpdateUserHandler_InvalidID(t *testing.T) {
    app := newTestApp()
    req := httptest.NewRequest(http.MethodPatch, "/v1/users/update/", nil)
    rr := httptest.NewRecorder()

    app.updateUserHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestDeleteUserHandler_InvalidID(t *testing.T) {
    app := newTestApp()
    req := httptest.NewRequest(http.MethodDelete, "/v1/users/delete/", nil)
    rr := httptest.NewRecorder()

    app.deleteUserHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}

func TestUpdatePasswordHandler_MissingNewPassword(t *testing.T) {
    app := newTestApp()
    req := httptest.NewRequest(http.MethodPatch, "/v1/users/update-password/", bytes.NewBufferString(`{"new_password":""}`))
    req.Header.Set("Content-Type", "application/json")
    rr := httptest.NewRecorder()

    app.updatePasswordHandler(rr, req)

    if rr.Code != http.StatusNotFound {
        t.Fatalf("expected status %d; got %d; body=%s", http.StatusNotFound, rr.Code, rr.Body.String())
    }
}