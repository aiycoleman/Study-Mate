-- Filename: migrations/000006_create_permissions_table.up.sql
CREATE TABLE IF NOT EXISTS permissions (
    id bigserial PRIMARY KEY,
    code text NOT NULL
);