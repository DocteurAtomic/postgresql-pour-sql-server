-- Module D2, cleanup. Lab database, psql. Leaves the database and the instance as they
-- were: drops the tables of the module, pgcrypto, the default privileges, the grants and
-- the md2_* roles. DROP OWNED works in the current database only: if you played the
-- module in two databases, run it in each before DROP ROLE. A REVOKE does not bring an
-- ACL back to NULL: the schemas and tables granted to md2_lecture now show the owner's
-- privileges explicitly (postgres=UC/postgres), which grants the same thing.
drop table if exists outils.md2_session, outils.md2_contact, outils.md2_tarif, outils.md2_tarif2;
alter default privileges for role postgres in schema outils revoke select on tables from md2_lecture;
drop owned by md2_app, md2_analyste, md2_lecture;
drop role md2_app, md2_analyste, md2_lecture;
drop extension if exists pgcrypto;

select (select count(*) from pg_roles where rolname like 'md2\_%') as md2_roles,
       (select count(*) from pg_class where relname like 'md2\_%') as md2_tables,
       (select count(*) from pg_default_acl) as default_acls,
       (select count(*) from pg_namespace where nspacl::text like '%md2%')
       + (select count(*) from pg_class where relacl::text like '%md2%') as acls_naming_md2,
       (select string_agg(extname, ', ') from pg_extension) as extensions;
