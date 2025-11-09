// Filename: internal/data/study_sessions.go

package data

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/aiycoleman/Study-Mate/internal/validator"
)

type StudySession struct {
	ID          int64     `json:"id"`
	UserID      int64     `json:"user_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Subject     string    `json:"subject"`
	StartTime   time.Time `json:"start_time"`
	EndTime     time.Time `json:"end_time"`
	IsCompleted bool      `json:"is_completed"`
	CreatedAt   time.Time `json:"created_at"`
}

// Validation checks for StudySession
func ValidateStudySession(v *validator.Validator, s *StudySession) {
	v.Check(s.Title != "", "title", "must be provided")
	v.Check(len(s.Title) <= 100, "title", "must not be more than 100 bytes long")
	v.Check(s.UserID > 0, "user_id", "must be a valid user ID")

	v.Check(!s.StartTime.IsZero(), "start_time", "must be provided")
	v.Check(!s.EndTime.IsZero(), "end_time", "must be provided")
	v.Check(s.EndTime.After(s.StartTime), "end_time", "must be after the start time")

	// Optional fields but should not exceed length limits
	v.Check(len(s.Description) <= 500, "description", "must not be more than 500 bytes long")
	v.Check(len(s.Subject) <= 100, "subject", "must not be more than 100 bytes long")
}

type StudySessionModel struct {
	DB *sql.DB
}

// Insert a new study session
func (m StudySessionModel) Insert(s *StudySession) error {
	query := `
		INSERT INTO study_sessions (user_id, title, description, subject, start_time, end_time, is_completed)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING session_id, created_at`

	args := []any{s.UserID, s.Title, s.Description, s.Subject, s.StartTime, s.EndTime, s.IsCompleted}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, args...).Scan(&s.ID, &s.CreatedAt)
}

// Get a single study session by ID
func (m StudySessionModel) Get(id int64) (*StudySession, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT session_id, user_id, title, description, subject, start_time, end_time, is_completed, created_at
		FROM study_sessions
		WHERE session_id = $1`

	var s StudySession

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(
		&s.ID,
		&s.UserID,
		&s.Title,
		&s.Description,
		&s.Subject,
		&s.StartTime,
		&s.EndTime,
		&s.IsCompleted,
		&s.CreatedAt,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &s, nil
}

// Update an existing study session
func (m StudySessionModel) Update(s *StudySession) error {
	query := `
		UPDATE study_sessions
		SET title = $1, description = $2, subject = $3, start_time = $4, end_time = $5, is_completed = $6
		WHERE session_id = $7
		RETURNING session_id, user_id, title, description, subject, start_time, end_time, is_completed, created_at`

	args := []any{s.Title, s.Description, s.Subject, s.StartTime, s.EndTime, s.IsCompleted, s.ID}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, args...).Scan(
		&s.ID,
		&s.UserID,
		&s.Title,
		&s.Description,
		&s.Subject,
		&s.StartTime,
		&s.EndTime,
		&s.IsCompleted,
		&s.CreatedAt,
	)
}

// Delete a study session
func (m StudySessionModel) Delete(id int64) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `
		DELETE FROM study_sessions
		WHERE session_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := m.DB.ExecContext(ctx, query, id)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return ErrRecordNotFound
	}

	return nil
}

// GetAll study sessions with optional filters (by subject/title/is_completed)
func (m StudySessionModel) GetAll(title string, subject string, isCompleted *bool, filters Filters) ([]*StudySession, Metadata, error) {
	query := `
		SELECT COUNT(*) OVER(), session_id, user_id, title, description, subject, start_time, end_time, is_completed, created_at
		FROM study_sessions
		WHERE (to_tsvector('simple', title) @@ plainto_tsquery('simple', $1) OR $1 = '')
		AND (to_tsvector('simple', subject) @@ plainto_tsquery('simple', $2) OR $2 = '')
		AND ($3::boolean IS NULL OR is_completed = $3)
		ORDER BY ` + filters.sortColumn() + ` ` + filters.sortDirection() + `, session_id ASC
		LIMIT $4 OFFSET $5`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, title, subject, isCompleted, filters.limit(), filters.offset())
	if err != nil {
		return nil, Metadata{}, err
	}
	defer rows.Close()

	totalRecords := 0
	var sessions []*StudySession

	for rows.Next() {
		var s StudySession
		err := rows.Scan(
			&totalRecords,
			&s.ID,
			&s.UserID,
			&s.Title,
			&s.Description,
			&s.Subject,
			&s.StartTime,
			&s.EndTime,
			&s.IsCompleted,
			&s.CreatedAt,
		)
		if err != nil {
			return nil, Metadata{}, err
		}
		sessions = append(sessions, &s)
	}

	if err = rows.Err(); err != nil {
		return nil, Metadata{}, err
	}

	metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)
	return sessions, metadata, nil
}
