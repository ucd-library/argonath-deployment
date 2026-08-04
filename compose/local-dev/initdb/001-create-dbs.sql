-- Runs once via docker-entrypoint-initdb.d on first postgres startup
-- (fresh pg_data volume). Creates the per-app databases that share this
-- postgres instance in local-dev.

SELECT 'CREATE DATABASE dagster'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dagster')\gexec

SELECT 'CREATE DATABASE superset'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'superset')\gexec
