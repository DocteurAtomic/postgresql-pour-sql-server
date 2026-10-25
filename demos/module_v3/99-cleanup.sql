-- Module V3, cleanup. Lab database, psql. Leaves the database as it was restored: drops the
-- demo tables, and the advisory locks this session could still hold.
drop table if exists outils.mv3_draft;
drop table if exists outils.mv3_inscription;
drop table if exists outils.mv3_convocation;
select pg_advisory_unlock_all();

select count(*) as leftover_tables
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'outils' and c.relname like 'mv3\_%';
