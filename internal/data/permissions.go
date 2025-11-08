// Filename: internal/data/permissions.go
package data

import (
	"context"
	"database/sql"
	"slices"
	"time"

	"github.com/lib/pq"
)

type Permissions []string

func (p Permissions) Include(code string) bool {
	return slices.Contains(p, code)
}

type PermissionModel struct {
	DB *sql.DB
}

func (p PermissionModel) GetAllForUser(userID int64) (Permissions, error) {
	query := `
               SELECT permissions.code
               FROM permissions 
               INNER JOIN users_permissions ON 
               users_permissions.permission_id = permissions.id
			   INNER JOIN users ON users_permissions.user_id = users.id
               WHERE users.id = $1
            `
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	rows, err := p.DB.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	// Store the permissions for the user in our slice
	var permissions Permissions
	for rows.Next() {
		var permission string

		err := rows.Scan(&permission)
		if err != nil {
			return nil, err
		}

		permissions = append(permissions, permission)
	}

	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return permissions, nil

}

func (p PermissionModel) AddForUser(userID int64, codes ...string) error {
	query := `
        INSERT INTO users_permissions (user_id, permission_id)
        SELECT $1, permissions.id FROM permissions 
        WHERE permissions.code = ANY($2)
       `
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	// slices need to be converted to arrays to work in PostgreSQL
	_, err := p.DB.ExecContext(ctx, query, userID, pq.Array(codes))

	return err

}

// Add permissions to activated user
func (p PermissionModel) AddActivatedPermissions(userID int64) error {
	// Define the permissions to grant
	permissions := []string{
		"quotes:write",
		"goals:read",
		"goals:write",
		"study_sessions:read",
		"study_sessions:write",
		"users:read",
		"users:write",
	}

	query := `
		INSERT INTO users_permissions (user_id, permission_id)
		SELECT $1, id FROM permissions
		WHERE code = ANY($2)
	`

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	_, err := p.DB.ExecContext(ctx, query, userID, pq.Array(permissions))
	return err
}

func (p PermissionModel) HasForUser(userID int64, permissionCode string) (bool, error) {
	query := `
        SELECT COUNT(*)
        FROM users_permissions up
        INNER JOIN permissions perm ON up.permission_id = perm.id
        WHERE up.user_id = $1 AND perm.code = $2;
    `

	var count int
	err := p.DB.QueryRow(query, userID, permissionCode).Scan(&count)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}
