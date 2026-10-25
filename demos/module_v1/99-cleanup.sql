-- Module V1, cleanup. Lab database, psql. Drops the copies an interrupted run leaves
-- behind; the module creates nothing else, so the database is as it was restored.
drop table if exists outils.mv1_session_archive;
drop table if exists outils.mv1_session;
drop table if exists outils.mv1_import;
drop table if exists outils.mv1_catalog;
drop table if exists outils.mv1_exercise;

select count(*) as leftover_copies
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'outils' and c.relname like 'mv1\_%';
