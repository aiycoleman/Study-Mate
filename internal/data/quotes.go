// Filename: internal/data/errors.go
package data

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/aiycoleman/Study-Mate/internal/validator"
)

type Quote struct {
	ID        int64     `json:"id"`
	Username  string    `json:"username"`
	UserID    int64     `json:"user_id"`
	Content   string    `json:"content"`
	CreatedAt time.Time `json:"created_at"`
}

// Performs validation checks for Quote input
func ValidateQuote(v *validator.Validator, quote *Quote) {
	v.Check(quote.Content != "", "content", "must be provided")
	v.Check(len(quote.Content) <= 500, "content", "must not be more than 500 bytes long")
	v.Check(quote.UserID > 0, "user_id", "must be a valid user ID")
}

type QuoteModel struct {
	DB *sql.DB
}

// Insert a new quote into the database
func (q QuoteModel) Insert(quote *Quote) error {
	query := `
		INSERT INTO quotes (user_id, content)
		VALUES ($1, $2)
		RETURNING quote_id, created_at`

	args := []any{quote.UserID, quote.Content}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return q.DB.QueryRowContext(ctx, query, args...).Scan(&quote.ID, &quote.CreatedAt)
}

// Get a specific quote from the database
func (q QuoteModel) Get(id int64) (*Quote, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT quote_id, user_id, content, created_at
		FROM quotes
		WHERE quote_id = $1`

	var quote Quote

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := q.DB.QueryRowContext(ctx, query, id).Scan(
		&quote.ID,
		&quote.UserID,
		&quote.Content,
		&quote.CreatedAt,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &quote, nil
}

// Update a specific quote
func (q QuoteModel) Update(quote *Quote) error {
	query := `
		UPDATE quotes
		SET content = $1
		WHERE quote_id = $2
		RETURNING quote_id, user_id, content, created_at`

	args := []any{quote.Content, quote.ID}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return q.DB.QueryRowContext(ctx, query, args...).Scan(
		&quote.ID,
		&quote.UserID,
		&quote.Content,
		&quote.CreatedAt,
	)
}

// Delete a specific quote
func (q QuoteModel) Delete(id int64) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `
		DELETE FROM quotes
		WHERE quote_id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := q.DB.ExecContext(ctx, query, id)
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

// GetAllForUser quotes for a specific user
func (q QuoteModel) GetAllForUser(userID int64, content string, filters Filters) ([]*Quote, Metadata, error) {
    query := `
       SELECT COUNT(*) OVER(), q.quote_id, q.user_id, u.username, q.content, q.created_at
       FROM quotes q
       JOIN users u ON q.user_id = u.id
       WHERE q.user_id = $1
       AND (to_tsvector('simple', q.content) @@ plainto_tsquery('simple', $2) OR $2 = '')
       ORDER BY  + filters.sortColumn() +   + filters.sortDirection() + , quote_id ASC
       LIMIT $3 OFFSET $4`

    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    rows, err := q.DB.QueryContext(ctx, query, userID, content, filters.limit(), filters.offset())
    if err != nil {
       return nil, Metadata{}, err
    }
    defer rows.Close()

    totalRecords := 0
    var quotes []*Quote

    for rows.Next() {
       var quote Quote
       err := rows.Scan(
          &totalRecords,
          &quote.ID,
          &quote.UserID,
          &quote.Username,
          &quote.Content,
          &quote.CreatedAt,
       )
       if err != nil {
          return nil, Metadata{}, err
       }
       quotes = append(quotes, &quote)
    }

    if err = rows.Err(); err != nil {
       return nil, Metadata{}, err
    }

    metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)

    return quotes, metadata, nil
}

// Get all quotes (with optional content search + pagination)
func (q QuoteModel) GetAll(content string, filters Filters) ([]*Quote, Metadata, error) {
	query := `
		SELECT COUNT(*) OVER(), q.quote_id, q.user_id, u.username, q.content, q.created_at
		FROM quotes q
		JOIN users u ON q.user_id = u.id
		WHERE (to_tsvector('simple', q.content) @@ plainto_tsquery('simple', $1) OR $1 = '')
		ORDER BY ` + filters.sortColumn() + ` ` + filters.sortDirection() + `, quote_id ASC
		LIMIT $2 OFFSET $3`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := q.DB.QueryContext(ctx, query, content, filters.limit(), filters.offset())
	if err != nil {
		return nil, Metadata{}, err
	}
	defer rows.Close()

	totalRecords := 0
	var quotes []*Quote

	for rows.Next() {
		var quote Quote
		err := rows.Scan(
			&totalRecords,
			&quote.ID,
			&quote.UserID,
			&quote.Username,
			&quote.Content,
			&quote.CreatedAt,
		)
		if err != nil {
			return nil, Metadata{}, err
		}
		quotes = append(quotes, &quote)
	}

	if err = rows.Err(); err != nil {
		return nil, Metadata{}, err
	}

	metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)

	return quotes, metadata, nil
}

func (q QuoteModel) GetByID(id int64) (*Quote, error) {
	query := `
        SELECT q.quote_id, q.content, q.created_at, u.username 
		FROM quotes q 
		JOIN users u 
		ON q.user_id = u.id 
		WHERE q.quote_id = $1
    `
	var quote Quote
	err := q.DB.QueryRow(query, id).Scan(&quote.ID, &quote.UserID, &quote.Username, &quote.Content, &quote.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &quote, nil
}
