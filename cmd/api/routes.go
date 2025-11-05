// Filename: cmd/api/routes.go

package main

import (
	// "expvar"
	"net/http"

	"github.com/julienschmidt/httprouter"
)

// routes specifies our routes
func (app *application) routes() http.Handler {
	// setup a new routes
	router := httprouter.New()

	// handle 404
	router.NotFound = http.HandlerFunc(app.notFoundResponse)
	// handle 405
	router.MethodNotAllowed = http.HandlerFunc(app.methodNotAllowedResponse)

	// setup routes
	router.HandlerFunc(http.MethodGet, "/v1/healthcheck", app.healthcheckHandler)

	// Users
	router.HandlerFunc(http.MethodPost, "/v1/users", app.registerUserHandler)
	router.HandlerFunc(http.MethodPut, "/v1/users/activated", app.activateUserHandler)
	router.HandlerFunc(http.MethodPost, "/v1/tokens/authentication", app.createAuthenticationTokenHandler)

	// router.HandlerFunc(http.MethodPatch, "/v1/users/update/:id", app.requirePermission("users:write", app.requireActivatedUser(app.updateUserHandler)))
	// router.HandlerFunc(http.MethodGet, "/v1/users/details", app.requirePermission("users:read", app.requireActivatedUser(app.listUsersHandler)))
	// router.HandlerFunc(http.MethodDelete, "/v1/users/delete/:id", app.requirePermission("users:write", app.requireActivatedUser(app.deleteUserHandler)))
	// router.HandlerFunc(http.MethodPatch, "/v1/users/update-password/:id", app.requirePermission("users:write", app.requireActivatedUser(app.updatePasswordHandler)))

	// router.Handler(http.MethodGet, "/v1/observability/course/metrics", expvar.Handler())

	return app.metrics(app.recoverPanic(app.enableCORS(app.rateLimit(app.authenticate(router)))))
	// return nil
}
