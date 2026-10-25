-- Module V7, cleanup. Lab database, psql. Leaves the database as it was restored: drops the
-- schema of the Entity Framework demo (clip V7.4), the function of clip V7.5 and the
-- extension pg_stat_statements, and the prepared statements of this session.
drop schema if exists mv7_app cascade;
drop function if exists outils.mv7_enrolled(smallint);
drop extension if exists pg_stat_statements;
deallocate all;

select (select count(*) from pg_namespace where nspname = 'mv7_app') as mv7_schemas,
       (select count(*) from pg_proc where proname like 'mv7\_%') as mv7_functions,
       (select string_agg(extname, ', ') from pg_extension) as extensions;
