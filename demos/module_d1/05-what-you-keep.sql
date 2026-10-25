-- Clip D1.5: what the lab lets you do that a managed service takes away. Lab database,
-- psql. Read only.
-- On the lab you are a superuser; managed services give a role without SUPERUSER.
select rolname, rolsuper, rolcreaterole, rolcreatedb, rolreplication
from pg_roles
where rolname = current_user;

-- The extensions this image could install, and the libraries loaded at start.
select count(*) as available_extensions from pg_available_extensions;
show shared_preload_libraries;

-- ALTER SYSTEM can be refused by the instance itself (allow_alter_system, since 17).
select name, setting, context from pg_settings where name = 'allow_alter_system';

-- The superuser reads the files of PGDATA, the server log included.
select btrim(pg_read_file('PG_VERSION'), E'\n') as pg_version_file;
