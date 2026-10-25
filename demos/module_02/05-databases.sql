-- Clip 2.5: databases, schemas, and queries across databases. Lab database, psql,
-- after 00-setup.sql. Three statements fail on purpose: ON_ERROR_STOP is off around them.
select current_database(), current_user;

-- A connection belongs to one database: there is no three-part name.
\set ON_ERROR_STOP off
select count(*) from postgres.pg_catalog.pg_class;
\set ON_ERROR_STOP on

-- search_path plays the role of the default schema.
show search_path;
\set ON_ERROR_STOP off
select count(*) from session;
\set ON_ERROR_STOP on
set search_path = stage, public;
select count(*) from session;
reset search_path;

-- postgres_fdw: a foreign server that points back to this database, through a
-- second connection. A real migration would point it to another database or host.
select format('create server m02_loopback foreign data wrapper postgres_fdw '
              'options (dbname %L, application_name %L)',
              current_database(), 'm02_fdw') \gexec
create user mapping for current_user server m02_loopback;
create schema m02_remote;
import foreign schema stage limit to (stage) from server m02_loopback into m02_remote;

select count(*) as stages_through_fdw from m02_remote.stage;

-- The foreign query was served by another backend process, still connected.
select pid, backend_type, application_name, state
from pg_stat_activity
where application_name = 'm02_fdw';

-- template1 is the model of every new database; template0 stays pristine.
select datname, datistemplate, datallowconn
from pg_database
where datname in ('template0', 'template1', 'postgres')
order by datname;

-- Any database can be a template, but not while another session is connected to it:
-- the postgres_fdw connection above is one.
\set ON_ERROR_STOP off
select format('create database m02_demo template %I', current_database()) \gexec
\set ON_ERROR_STOP on

drop schema m02_remote cascade;
drop server m02_loopback cascade;    -- also closes the postgres_fdw connection

-- A new database is a copy of template1.
create database m02_demo;
select datname from pg_database where datname = 'm02_demo';
drop database m02_demo;
