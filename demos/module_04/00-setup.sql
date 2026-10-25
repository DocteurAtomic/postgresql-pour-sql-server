-- Module 4, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_04/00-setup.sql
-- Creates the two extensions the module uses. Every other object is created and dropped
-- by the script that needs it; 99-cleanup.sql drops what an interrupted run leaves behind.
create extension if not exists citext;       -- a case-insensitive text type (clip 4.3)
create extension if not exists pgstattuple;  -- the fill of an index (clip 4.6)

select extname, extversion
from pg_extension
where extname in ('citext', 'pgstattuple')
order by extname;
