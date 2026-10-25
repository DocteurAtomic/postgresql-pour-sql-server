-- Clip D2.1: one object for login, user and role. Lab database, psql.
-- Creates the roles md2_lecture, md2_app and md2_analyste, used by the next clips and
-- dropped by 99-cleanup.sql.

-- The catalogs of roles are shared by every database of the instance.
select relname, relisshared
from pg_class
where relname in ('pg_authid', 'pg_auth_members', 'pg_class')
order by relname;

-- On a fresh instance, one role can log in: the superuser created by initdb.
select rolname, rolsuper, rolinherit, rolcreaterole, rolcreatedb, rolcanlogin,
       rolreplication, rolbypassrls
from pg_roles
where rolname not like 'pg\_%';

-- A group is a role without LOGIN; CREATE USER is CREATE ROLE ... LOGIN.
create role md2_lecture;
create role md2_app login password 'demo-app';
create user md2_analyste password 'demo-analyste';
grant md2_lecture to md2_analyste;

select r.rolname, r.rolcanlogin,
       array(select g.rolname
             from pg_auth_members m join pg_roles g on g.oid = m.roleid
             where m.member = r.oid) as member_of
from pg_roles r
where r.rolname like 'md2\_%'
order by r.rolname;

-- SET ROLE is the EXECUTE AS of PostgreSQL: current_user changes, session_user does not.
set role md2_analyste;
select session_user, current_user;
reset role;

-- A migrated default: SUSER_SNAME() became a string constant, not a function call.
select column_name, column_default
from information_schema.columns
where table_schema = 'formateur' and table_name = 'formateur' and column_name = 'creationuser';

-- The predefined roles of the instance.
select rolname
from pg_roles
where rolname like 'pg\_%'
order by rolname;

-- pg_read_all_data: SELECT on every table and USAGE on every schema, in every database.
\set ON_ERROR_STOP off
set role md2_analyste;
select count(*) from inscription.inscription;
reset role;
\set ON_ERROR_STOP on
grant pg_read_all_data to md2_analyste;
set role md2_analyste;
select count(*) from inscription.inscription;
reset role;

-- pg_monitor granted WITH INHERIT FALSE: the privileges come only after SET ROLE.
grant pg_monitor to md2_app with inherit false;
set role md2_app;
select usename, state, query
from pg_stat_activity
where pid = pg_backend_pid();
set role pg_monitor;
select usename, state, query
from pg_stat_activity
where pid = pg_backend_pid();
reset role;

select r.rolname as member, g.rolname as role, m.inherit_option, m.set_option, m.admin_option
from pg_auth_members m
join pg_roles r on r.oid = m.member
join pg_roles g on g.oid = m.roleid
where r.rolname like 'md2\_%'
order by member, role;
