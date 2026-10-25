-- Module V7 exercise, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_v7/1-setup.sql
-- Creates the extension pg_stat_statements if it is not there; 3-cleanup.sql drops it.
-- The prepared statement of the exercise lives in your own psql session: nothing else here.
create extension if not exists pg_stat_statements;
select extname, extversion from pg_extension where extname = 'pg_stat_statements';
