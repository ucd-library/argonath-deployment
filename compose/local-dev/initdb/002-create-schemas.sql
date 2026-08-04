-- Runs once via docker-entrypoint-initdb.d, against the default `postgres`
-- database (POSTGRES_DB is unset, so it defaults to POSTGRES_USER).
-- Schemas for services that share this database.

CREATE SCHEMA IF NOT EXISTS auth_gateway;
