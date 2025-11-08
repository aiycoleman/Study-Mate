// Filename: internal/data/users.go
package data

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/aiycoleman/Study-Mate/internal/validator"
	"golang.org/x/crypto/bcrypt"
)

var AnonymousUser = &User{}

type User struct {
	ID        int64     `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	Password  password  `json:"-"`
	Activated bool      `json:"activated"`
	Version   int       `json:"-"`
	CreatedAt time.Time `json:"created_at"`
}

type password struct {
	plaintext *string
	hash      []byte
}

func (p *password) Set(plaintextPassword string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(plaintextPassword), 12)

	if err != nil {
		return err
	}

	p.plaintext = &plaintextPassword
	p.hash = hash

	return nil
}

// Compare plaintext password with the saved-hashed version
func (p *password) Matches(plaintextPassword string) (bool, error) {
	err := bcrypt.CompareHashAndPassword(p.hash, []byte(plaintextPassword))

	if err != nil {
		switch {
		case errors.Is(err, bcrypt.ErrMismatchedHashAndPassword):
			return false, nil
		default:
			return false, err
		}
	}
	return true, nil
}

// validate  email address
func ValidateEmail(v *validator.Validator, email string) {
	v.Check(email != "", "email", "must be provided")
	v.Check(validator.Matches(email, validator.EmailRX), "email", "must be provided")
}

// check if password provided is valid
func ValidatePasswordPlaintext(v *validator.Validator, password string) {
	v.Check(password != "", "password", "must be provided")
	v.Check(len(password) >= 8, "password", "must be at least 8 bytes long")
	v.Check(len(password) <= 12, "password", "must not be more than 72 bytes long")
}

// validate user
func ValidateUser(v *validator.Validator, user *User) {
	v.Check(user.Username != "", "username", "must be provided")
	v.Check(len(user.Username) <= 200, "username", "must not be more than 200 bytes long")

	// validate email for user
	ValidateEmail(v, user.Email)
	// validate the plain text password
	if user.Password.plaintext != nil {
		ValidatePasswordPlaintext(v, *user.Password.plaintext)
	}
	// check if we messed up in our codebase
	if user.Password.hash == nil {
		panic("missing password hash for user")
	}

}

// Specify a custom duplicate email error message
var ErrDuplicateEmail = errors.New("duplicate email")

// Setup the struct
type UserModel struct {
	DB *sql.DB
}

// Insert a new user into the database
func (u UserModel) Insert(user *User) error {
	query := `
	INSERT INTO users (username, email, password_hash, activated) 
	VALUES ($1, $2, $3, $4)
	RETURNING id, created_at, version
   `
	args := []any{user.Username, user.Email, user.Password.hash, user.Activated}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	// if an email address already exists we will get a pq error message
	err := u.DB.QueryRowContext(ctx, query, args...).Scan(&user.ID, &user.CreatedAt, &user.Version)

	if err != nil {
		switch {
		case err.Error() == `pq: duplicate key value violates unique constraints "users_email_key`:
			return ErrDuplicateEmail
		default:
			return err
		}
	}

	return nil

}

// Get a user from the database based on their email provided
func (u UserModel) GetByEmail(email string) (*User, error) {

	query := `
		SELECT id, created_at, username, email, password_hash, activated, version
		FROM users
		WHERE email = $1
	   `
	var user User

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := u.DB.QueryRowContext(ctx, query, email).Scan(
		&user.ID,
		&user.CreatedAt,
		&user.Username,
		&user.Email,
		&user.Password.hash,
		&user.Activated,
		&user.Version,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &user, nil
}

// Update a User
func (u UserModel) Update(user *User) error {
	query := `
        UPDATE users 
        SET username = $1, email = $2, password_hash = $3,
            activated = $4, version = version + 1
        WHERE id = $5 AND version = $6
        RETURNING version
        `

	args := []any{
		user.Username,
		user.Email,
		user.Password.hash,
		user.Activated,
		user.ID,
		user.Version,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := u.DB.QueryRowContext(ctx, query, args...).Scan(&user.Version)

	// Check for errors during update
	if err != nil {
		switch {
		case err.Error() == `pq: duplicate key value violates unique constraint "users_email_key"`:
			return ErrDuplicateEmail
		case errors.Is(err, sql.ErrNoRows):
			return ErrEditConflict
		default:
			return err
		}
	}

	return nil
}

// Verify token to user. We need to hash the passed in token
func (u UserModel) GetForToken(tokenScope, tokenPlaintext string) (*User, error) {
	tokenHash := sha256.Sum256([]byte(tokenPlaintext))

	// We will do a join- I hope you still remember how to do a join
	query := `
		SELECT users.id, users.created_at, users.username,users.email, users.password_hash, users.activated, users.version
		FROM users
		INNER JOIN tokens
		ON users.id = tokens.user_id
		WHERE tokens.hash = $1
		AND tokens.scope = $2 
		AND tokens.expiry > $3
		`

	args := []any{tokenHash[:], tokenScope, time.Now()}
	var user User
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	err := u.DB.QueryRowContext(ctx, query, args...).Scan(
		&user.ID,
		&user.CreatedAt,
		&user.Username,
		&user.Email,
		&user.Password.hash,
		&user.Activated,
		&user.Version,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	// Return the matching user.
	return &user, nil
}

func (u *User) IsAnonymous() bool {
	return u == AnonymousUser
}

// Activatng the user
func (u UserModel) Activate(user *User) error {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	query := `
        UPDATE users
        SET activated = true, version = version + 1
        WHERE id = $1 AND version = $2
        RETURNING version
    `
	err := u.DB.QueryRowContext(ctx, query, user.ID, user.Version).Scan(&user.Version)
	if err != nil {
		return err
	}

	p := PermissionModel{DB: u.DB}
	err = p.AddActivatedPermissions(user.ID)
	// Add default permissions to the user upon activation
	if err != nil {
		return fmt.Errorf("user activated but failed to add permissions: %w", err)
	}

	return nil
}

// GetAll retrieves all users (with optional username search and pagination).
func (u UserModel) GetAll(id int64, username, email string, filters Filters) ([]*User, Metadata, error) {
	query := fmt.Sprintf(`
        SELECT COUNT(*) OVER(), id, username, email, activated, version, created_at
        FROM users
        WHERE (to_tsvector('simple', username) @@ plainto_tsquery('simple', $1) OR $1 = '')
        ORDER BY %s %s, id ASC
        LIMIT $2 OFFSET $3`,
		filters.sortColumn(), filters.sortDirection())

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := u.DB.QueryContext(ctx, query, username, filters.PageSize, (filters.Page-1)*filters.PageSize)
	if err != nil {
		return nil, Metadata{}, err
	}
	defer rows.Close()

	totalRecords := 0
	users := []*User{}

	for rows.Next() {
		var user User
		err := rows.Scan(
			&totalRecords,
			&user.ID,
			&user.Username,
			&user.Email,
			&user.Activated,
			&user.Version,
			&user.CreatedAt,
		)
		if err != nil {
			return nil, Metadata{}, err
		}
		users = append(users, &user)
	}

	if err = rows.Err(); err != nil {
		return nil, Metadata{}, err
	}

	metadata := calculateMetadata(totalRecords, filters.Page, filters.PageSize)
	return users, metadata, nil
}

// GetByID fetches a single user by ID.
func (u UserModel) GetByID(id int64) (*User, error) {
	if id < 1 {
		return nil, ErrRecordNotFound
	}

	query := `
		SELECT id, username, email, password_hash, activated, version, created_at
		FROM users
		WHERE id = $1
	`

	var user User

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	err := u.DB.QueryRowContext(ctx, query, id).Scan(
		&user.ID,
		&user.Username,
		&user.Email,
		&user.Password.hash,
		&user.Activated,
		&user.Version,
		&user.CreatedAt,
	)

	if err != nil {
		switch {
		case errors.Is(err, sql.ErrNoRows):
			return nil, ErrRecordNotFound
		default:
			return nil, err
		}
	}

	return &user, nil
}

// UpdateUser updates username, email, and activation status.
func (u UserModel) UpdateUser(user *User) error {
	query := `
		UPDATE users
		SET username = $1, email = $2, activated = $3, version = version + 1
		WHERE id = $4 AND version = $5
		RETURNING version
	`

	args := []any{
		user.Username,
		user.Email,
		user.Activated,
		user.ID,
		user.Version,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	return u.DB.QueryRowContext(ctx, query, args...).Scan(&user.Username, user.Email, user.Activated, user.ID, user.Version)
}

// Delete removes a user by ID.
func (u UserModel) Delete(id int64) error {
	if id < 1 {
		return ErrRecordNotFound
	}

	query := `DELETE FROM users WHERE id = $1`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	result, err := u.DB.ExecContext(ctx, query, id)
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

// UpdatePassword changes a user’s password and increments version.
func (u UserModel) UpdatePassword(id int64, newPassword string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	query := `
		UPDATE users
		SET password_hash = $1, version = version + 1
		WHERE id = $2
		RETURNING id
	`

	var returnedID int64
	err = u.DB.QueryRow(query, hashedPassword, id).Scan(&returnedID)
	if err != nil {
		return err
	}

	return nil
}
