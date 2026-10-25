-- Clip D4.3: the age of the transaction ids, and freezing. Lab database, psql, after
-- 00-setup.sql. One session; it creates outils.md4_archive and drops it at the end.

-- 1. The settings of freezing, and the safety limits of 32-bit transaction ids.
select name, setting
from pg_settings
where name in ('vacuum_freeze_min_age', 'vacuum_freeze_table_age', 'autovacuum_freeze_max_age',
               'vacuum_failsafe_age', 'vacuum_max_eager_freeze_failure_rate')
order by name;

-- 2. This database: the age of its oldest unfrozen transaction id, and how far it is from
-- the warnings (40 million before wraparound) and from the refusal (3 million before).
-- The limits apply to the oldest database of the instance, hence the second query.
select datname, age(datfrozenxid) as xid_age, mxid_age(datminmxid) as mxid_age,
       2147483647 - 40000000 - age(datfrozenxid) as before_warnings,
       2147483647 - 3000000 - age(datfrozenxid) as before_refusal
from pg_database
where datname = current_database();
select max(age(datfrozenxid)) as oldest_database_age from pg_database;

-- 3. The oldest tables of this database, their TOAST table included (the query of the
-- documentation, section 24.1.5).
select c.oid::regclass as table_name,
       greatest(age(c.relfrozenxid), age(t.relfrozenxid)) as xid_age
from pg_class as c
left join pg_class as t on c.reltoastrelid = t.oid
where c.relkind in ('r', 'm')
order by xid_age desc
limit 5;

-- 4. A table filled in one go, then left alone, like an archive.
drop table if exists outils.md4_archive;
create table outils.md4_archive with (autovacuum_enabled = off) as
select g as id, md5(g::text) as payload from generate_series(1, 100000) as g;
select relpages, relallvisible, relallfrozen, age(relfrozenxid) as xid_age
from pg_class where oid = 'outils.md4_archive'::regclass;
select * from pg_visibility_map_summary('outils.md4_archive');

-- A plain VACUUM sets the pages all-visible; it freezes only the rows older than
-- vacuum_freeze_min_age (50 million transactions), so here none.
vacuum (verbose, process_toast false) outils.md4_archive;
select relpages, relallvisible, relallfrozen, age(relfrozenxid) as xid_age
from pg_class where oid = 'outils.md4_archive'::regclass;

-- VACUUM FREEZE freezes every row: the pages become all-frozen, and the next aggressive
-- vacuums skip them.
vacuum (freeze, verbose, process_toast false) outils.md4_archive;
select relpages, relallvisible, relallfrozen, age(relfrozenxid) as xid_age
from pg_class where oid = 'outils.md4_archive'::regclass;
select * from pg_visibility_map_summary('outils.md4_archive');

drop table outils.md4_archive;
