-- Module 2, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_02/00-setup.sql
-- Creates the three extensions the module reads the instance with. Nothing else.
create extension if not exists pg_buffercache;  -- what is in shared_buffers (clip 2.2)
create extension if not exists pg_walinspect;   -- what a statement writes to the WAL (clip 2.3)
create extension if not exists postgres_fdw;    -- a query that reaches another database (clip 2.5)

select extname, extversion
from pg_extension
where extname in ('pg_buffercache', 'pg_walinspect', 'postgres_fdw')
order by extname;
