-- Clip D2.3: database, schema and table privileges, default privileges, owner.
-- Lab database, psql. Run after 01-roles.sql. Creates the tables outils.md2_tarif and
-- outils.md2_tarif2, dropped by 99-cleanup.sql. Some statements fail on purpose:
-- ON_ERROR_STOP is off around them.

-- CONNECT: PUBLIC has it on every database, so any role that can log in may connect.
select datname, datacl,
       has_database_privilege('md2_app', datname, 'CONNECT') as md2_app_can_connect
from pg_database
where datname = current_database();

-- The schemas of the database and their privileges: only the owner, postgres.
select nspname, nspowner::regrole as owner, nspacl
from pg_namespace
where nspname in ('public', 'stage', 'outils')
order by nspname;

-- md2_app connects, but sees nothing: schema first, then table.
\set ON_ERROR_STOP off
set role md2_app;
select count(*) from stage.session;
reset role;
grant usage on schema stage to md2_lecture;
grant md2_lecture to md2_app;
set role md2_app;
select count(*) from stage.session;
reset role;
\set ON_ERROR_STOP on

-- GRANT ... ON ALL TABLES IN SCHEMA: the tables that exist now.
grant select on all tables in schema stage to md2_lecture;
set role md2_app;
select count(*) from stage.session;
reset role;

-- The public schema since PostgreSQL 15: USAGE for everybody, CREATE for its owner only.
\set ON_ERROR_STOP off
set role md2_app;
create table public.md2_test (id int);
reset role;
\set ON_ERROR_STOP on

-- A table created after the GRANT is not covered by it.
grant usage on schema outils to md2_lecture;
grant select on all tables in schema outils to md2_lecture;
create table outils.md2_tarif (stageid int, prix numeric(8,2));
\set ON_ERROR_STOP off
set role md2_app;
select count(*) from outils.md2_tarif;
reset role;
\set ON_ERROR_STOP on

-- ALTER DEFAULT PRIVILEGES: for the tables that postgres will create in this schema.
alter default privileges for role postgres in schema outils grant select on tables to md2_lecture;
create table outils.md2_tarif2 (stageid int, prix numeric(8,2));
set role md2_app;
select count(*) from outils.md2_tarif2;
reset role;

select n.nspname, c.relname, c.relacl
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where c.relname in ('session', 'md2_tarif', 'md2_tarif2')
order by c.relname;

select defaclrole::regrole as for_role, defaclnamespace::regnamespace as in_schema,
       defaclobjtype as object_type, defaclacl
from pg_default_acl;

-- The owner: every right on the object, and nobody can take them away by REVOKE.
alter table outils.md2_tarif owner to md2_app;
select relname, relowner::regrole as owner, relacl
from pg_class
where relname = 'md2_tarif';

-- A role that owns objects or holds privileges cannot be dropped.
\set ON_ERROR_STOP off
drop role md2_app;
\set ON_ERROR_STOP on
