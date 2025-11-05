-- Filename: migrations/000008_insert_initial_permissions_table.down.sql
INSERT INTO permissions (code)
VALUES
   ('quotes:read'),
   ('quotes:write'),
   ('goals:read'),
   ('goals:write'),
   ('study_sessions:read'),
   ('study_sessions:write');
