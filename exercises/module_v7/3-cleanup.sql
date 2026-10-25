-- Module V7 exercise, cleanup. Lab database, psql. Drops the extension of 1-setup.sql and
-- the prepared statements of this session; the database is back as it was restored.
deallocate all;
drop extension if exists pg_stat_statements;
select string_agg(extname, ', ') as extensions from pg_extension;
