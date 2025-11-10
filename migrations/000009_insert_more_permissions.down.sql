-- Filename: migrations/000009_insert_more_permissions_table.down.sql
DELETE FROM permissions
WHERE code IN ('users:read', 'users:write');
