-- Module D2 exercise, starting point. Lab database, psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /exercises/module_d2/1-start.sql
-- Creates two login roles with no privilege at all. 4-cleanup.sql drops them.
create role md2x_app login password 'demo-app';
create role md2x_analyste login password 'demo-analyste';

-- Both can connect (PUBLIC has CONNECT), neither can read anything yet.
select rolname,
       has_database_privilege(rolname, current_database(), 'CONNECT') as can_connect,
       has_schema_privilege(rolname, 'stage', 'USAGE') as stage_usage
from pg_roles
where rolname like 'md2x\_%'
order by rolname;
