-- Clip V4.6: CREATE INDEX CONCURRENTLY, in one session. Lab database, psql, after
-- 00-setup.sql. Two statements fail on purpose: ON_ERROR_STOP is off around them.
-- The scenes with several sessions: 06a to 06e, played by demos/module_03/scene.sh.

-- Not inside a transaction block.
\set ON_ERROR_STOP off
begin;
create index concurrently mv4_inscription_contactid on outils.mv4_inscription (contactid);
rollback;

-- A failure leaves an invalid index behind: a unique index on a column with duplicates.
create unique index concurrently mv4_inscription_contactid_uq
    on outils.mv4_inscription (contactid);
\set ON_ERROR_STOP on
select indexrelid::regclass as index, indisvalid, indisready
from pg_index
where indrelid = 'outils.mv4_inscription'::regclass
order by 1;
\d outils.mv4_inscription

-- The planner ignores it.
explain (costs off)
select inscriptionid from outils.mv4_inscription where contactid = 1203;

-- DROP INDEX CONCURRENTLY, then build again (here, without UNIQUE).
drop index concurrently outils.mv4_inscription_contactid_uq;
create index concurrently mv4_inscription_contactid on outils.mv4_inscription (contactid);
select indexrelid::regclass as index, indisvalid, indisready
from pg_index
where indrelid = 'outils.mv4_inscription'::regclass
order by 1;
drop index outils.mv4_inscription_contactid;
