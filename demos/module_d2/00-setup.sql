-- Module D2, setup. Lab database (pachadataformation), psql:
--   docker compose exec db psql -U postgres -d pachadataformation -f /demos/module_d2/00-setup.sql
-- Roles are objects of the instance, not of the database: every role of the module is
-- named md2_*, and 99-cleanup.sql drops them with what they own or were granted.
-- Clip D2.4 needs pgcrypto and a copy of stage.session, both dropped by 99-cleanup.sql.
create extension if not exists pgcrypto;

create table outils.md2_session as
select sessionid, stageid, datedebut, prix, formateurid
from stage.session;

-- The roles of the instance before the module: the predefined pg_* roles and postgres.
select count(*) filter (where rolname like 'pg\_%') as predefined_roles,
       count(*) filter (where rolname not like 'pg\_%') as other_roles
from pg_roles;
