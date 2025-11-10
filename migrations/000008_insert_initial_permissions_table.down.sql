-- Filename: migrations/000008_insert_initial_permissions_table.down.sql
DELETE FROM permissions
WHERE code IN ('quotes:read', 'quotes:write', 'goals:read', 'goals:write', 'study_sessions:read', 'study_sessions:write');
