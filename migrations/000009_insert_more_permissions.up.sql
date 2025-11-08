-- Filename: migrations/000009_insert_more_permissions_table.down.sql
INSERT INTO permissions (code)
VALUES
   ('users:read'),
   ('users:write');