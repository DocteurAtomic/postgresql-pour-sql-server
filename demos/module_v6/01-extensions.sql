-- Clip V6.1: extensions. Lab database, psql, after 00-setup.sql.
-- Reads the catalog, then drops fuzzystrmatch and creates it again in an older version to
-- show ALTER EXTENSION ... UPDATE; the script ends with fuzzystrmatch 1.2, as setup left it.
-- One statement fails on purpose (an extension the image does not ship).
\set ON_ERROR_STOP off

-- 1. What the image ships, and what this database has installed.
select count(*) as available from pg_available_extensions;
select count(*) as installed from pg_extension;
\dx

-- 2. An extension is a control file and SQL scripts in the share directory, plus, for most
--    of them, a shared library. The control file of unaccent:
select pg_read_file('/usr/share/postgresql/18/extension/unaccent.control');

-- 3. What CREATE EXTENSION created: the objects that belong to unaccent.
\dx+ unaccent

-- 4. The versions, and the update path.
select name, version, installed, superuser, trusted
from pg_available_extension_versions
where name in ('fuzzystrmatch', 'unaccent', 'pg_trgm', 'vector')
order by name, version;
drop extension fuzzystrmatch;
create extension fuzzystrmatch version '1.1';
select extversion from pg_extension where extname = 'fuzzystrmatch';
alter extension fuzzystrmatch update;
select extversion from pg_extension where extname = 'fuzzystrmatch';

-- 5. An extension the image does not ship.
create extension pg_cron;

-- 6. A library loaded at startup: pg_stat_statements needs shared_preload_libraries, which
--    only a restart changes.
show shared_preload_libraries;

-- 7. A dependency: an index that uses an operator class of pg_trgm blocks DROP EXTENSION.
create index mv6_programme_titre_trgm on outils.mv6_programme using gin (titre gin_trgm_ops);
drop extension pg_trgm;
drop index outils.mv6_programme_titre_trgm;

\set ON_ERROR_STOP on
