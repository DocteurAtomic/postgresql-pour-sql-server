-- Module D5, cleanup. Lab database, psql. Leaves the database as it was restored: drops the
-- table of the blocking scenes and the extension pg_stat_statements. The throwaway
-- containers of the .sh scripts remove themselves.
drop table if exists outils.md5_session;
drop extension if exists pg_stat_statements;

select (select count(*) from pg_tables where tablename like 'md5\_%') as md5_tables,
       (select string_agg(extname, ', ') from pg_extension) as extensions,
       (select count(*) from pg_indexes
        where schemaname not in ('pg_catalog', 'information_schema')) as indexes;
