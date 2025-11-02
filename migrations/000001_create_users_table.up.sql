-- Filename: migrations/000001_create_users_table.up.sql
CREATE TABLE IF NOT EXISTS users (
  id bigserial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  email citext NOT NULL UNIQUE,
  password_hash bytea NOT NULL,
  activated bool NOT NULL DEFAULT false,
  version integer NOT NULL DEFAULT 1,
  created_at timestamp(0) WITH TIME ZONE NOT NULL DEFAULT NOW()
);
