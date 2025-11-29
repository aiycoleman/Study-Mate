package data

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/aiycoleman/Study-Mate/internal/validator"
)

type Goal struct {
	ID          int64     `json:"id"`
	UserID      int64     `json:"user_id"`
	GoalText    string    `json:"goal_text"`
	TargetDate  time.Time `json:"target_date"`
	IsCompleted bool      `json:"is_completed"`
	CreatedAt   time.Time `json:"created_at"`
}

// Validation checks for Goal input
func ValidateGoal(v *validator.Validator, goal *Goal) {
	v.Check(goal.GoalText != "", "goal_text", "must be provided")
	v.Check(len(goal.GoalText) <= 255, "goal_text", "must not be more than 255 bytes long")
	v.Check(!goal.TargetDate.IsZero(), "target_date", "must be provided")
	v.Check(goal.UserID > 0, "user_id", "must be a valid user ID")
}

type GoalModel struct {
	DB *sql.DB
}

// Insert a new goal into the database
func (m GoalModel) Insert(goal *Goal) error {
	query := `
		INSERT INTO goals (user_id, goal_text, target_date, is_completed)
		VALUES ($1, $2, $3, $4)
		RETURNING goal_id, created_at`

	args := []any{goal.UserID, goal.GoalText, goal.TargetDate, goal.IsCompleted}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, args...).Scan(&goal.ID, &goal.CreatedAt)
}

// Get a specific goal from the database
func (m GoalModel) Get(id int64) (*Goal, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT goal_id, user_id, goal_text, target_date, is_completed, created_at
		FROM goals
		WHERE goal_id = $1`

	var goal Goal

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := m.DB.QueryRowContext(ctx, query, id).Scan(
		&goal.ID,
		&goal.UserID,
		&goal.GoalText,
		&goal.TargetDate,
		&goal.IsCompleted,
		&goal.CreatedAt,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &goal, nil
}

// Update a specific goal
func (m GoalModel) Update(goal *Goal) error {
	query := `
		UPDATE goals
		SET goal_text = $1, target_date = $2, is_completed = $3
		WHERE goal_id = $4
		RETURNING goal_id, user_id, goal_text, target_date, is_completed, created_at`

	args := []any{goal.GoalText, goal.TargetDate, goal.IsCompleted, goal.ID}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return m.DB.QueryRowContext(ctx, query, args...).Scan(
		&goal.ID,
		&goal.UserID,
		&goal.GoalText,
		&goal.TargetDate,
		&goal.IsCompleted,
		&goal.CreatedAt,
	)
}

// Delete a specific goal
func (m GoalModel) Delete(id int64) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `
		DELETE FROM goals
		WHERE goal_id = $1`

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
// Get all goals for a specific user (filtered by user_id)
func (m GoalModel) GetAllForUser(userID int64, goalText string, target_date time.Time, isCompleted bool, filters Filters) ([]*Goal, Metadata, error) {
    query := `
       SELECT COUNT(*) OVER(), goal_id, user_id, goal_text, target_date, is_completed, created_at
       FROM goals
       WHERE user_id = $1
       AND (to_tsvector('simple', goal_text) @@ plainto_tsquery('simple', $2) OR $2 = '')
       ORDER BY  + filters.sortColumn() +   + filters.sortDirection() + , goal_id ASC
       LIMIT $3 OFFSET $4`

    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    rows, err := m.DB.QueryContext(ctx, query, userID, goalText, filters.limit(), filters.offset())
    if err != nil {
       return nil, Metadata{}, err
    }
    defer rows.Close()

    totalRecords := 0
    var goals []*Goal

    for rows.Next() {
       var goal Goal
       err := rows.Scan(
          &totalRecords,
          &goal.ID,
          &goal.UserID,
          &goal.GoalText,
          &goal.TargetDate,
          &goal.IsCompleted,
          &goal.CreatedAt,
       )
       if err != nil {
          return nil, Metadata{}, err
       }
       goals = append(goals, &goal)
    }

    if err = rows.Err(); err != nil {
       return nil, Metadata{}, err
    }

    metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)
    return goals, metadata, nil
}




// Get all goals (optionally filtered by completion status or goal text)
func (m GoalModel) GetAll(goalText string, target_date time.Time, isCompleted bool, filters Filters) ([]*Goal, Metadata, error) {
	query := `
		SELECT COUNT(*) OVER(), goal_id, user_id, goal_text, target_date, is_completed, created_at
		FROM goals
		WHERE (to_tsvector('simple', goal_text) @@ plainto_tsquery('simple', $1) OR $1 = '')
		AND ($2::boolean IS NULL OR is_completed = $2)
		ORDER BY ` + filters.sortColumn() + ` ` + filters.sortDirection() + `, goal_id ASC
		LIMIT $3 OFFSET $4`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := m.DB.QueryContext(ctx, query, goalText, isCompleted, filters.limit(), filters.offset())
	if err != nil {
		return nil, Metadata{}, err
	}
	defer rows.Close()

	totalRecords := 0
	var goals []*Goal

	for rows.Next() {
		var goal Goal
		err := rows.Scan(
			&totalRecords,
			&goal.ID,
			&goal.UserID,
			&goal.GoalText,
			&goal.TargetDate,
			&goal.IsCompleted,
			&goal.CreatedAt,
		)
		if err != nil {
			return nil, Metadata{}, err
		}
		goals = append(goals, &goal)
	}

	if err = rows.Err(); err != nil {
		return nil, Metadata{}, err
	}

	metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)

	return goals, metadata, nil
}
