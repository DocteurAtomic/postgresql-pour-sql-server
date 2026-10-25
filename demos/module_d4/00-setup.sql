-- Module D4, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d4/00-setup.sql
-- The three extensions of the module, all shipped with PostgreSQL. Each script creates its
-- own outils.md4_* tables and drops them at the end; 99-cleanup.sql drops what is left and
-- the extensions. What changes the instance (autovacuum_naptime, pg_resetwal, pg_repack,
-- pg_cron) runs in throwaway containers, the .sh files, marked "ci: skip".
create extension if not exists pgstattuple;   -- clips D4.2 and D4.4
create extension if not exists pg_visibility; -- clip D4.3
create extension if not exists amcheck;       -- clip D4.4
select extname, extversion from pg_extension order by extname;
