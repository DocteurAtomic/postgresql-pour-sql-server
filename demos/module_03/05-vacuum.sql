-- Clip 3.5: dead tuples, VACUUM, HOT updates. Lab database, psql, after 00-setup.sql.
-- One session. The copy of inscription.facture has autovacuum disabled, so that nothing
-- cleans it behind our back; never do that on a real table.

drop table if exists outils.m03_facture;
create table outils.m03_facture with (autovacuum_enabled = off) as
select * from inscription.facture;
alter table outils.m03_facture add primary key (facturecd);
vacuum outils.m03_facture;

-- The measure, used after each step: table and index size, live and dead tuples.
prepare measure as
select pg_size_pretty(pg_relation_size('outils.m03_facture')) as table_size,
       pg_size_pretty(pg_relation_size('outils.m03_facture_pkey')) as index_size,
       s.tuple_count, s.dead_tuple_count, round(s.free_percent) as free_pct
from pgstattuple('outils.m03_facture') as s;
execute measure;

-- 1. Every row updated once: 16,514 new versions, 16,514 dead ones.
update outils.m03_facture set relance = relance + 1;
execute measure;

-- 2. VACUUM marks the space of the dead tuples as free. The file keeps its size.
vacuum outils.m03_facture;
execute measure;

-- 3. VACUUM FULL rewrites the table into a new file, under an ACCESS EXCLUSIVE lock.
vacuum full outils.m03_facture;
execute measure;

-- The autovacuum settings, and the number of dead tuples that triggers it on two tables:
-- min(max threshold, base threshold + scale factor * rows).
select name, setting
from pg_settings
where name in ('autovacuum', 'autovacuum_naptime', 'autovacuum_vacuum_threshold',
               'autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_max_threshold',
               'autovacuum_freeze_max_age')
order by name;

select oid::regclass as table_name, reltuples::bigint as rows,
       least(current_setting('autovacuum_vacuum_max_threshold')::bigint,
             current_setting('autovacuum_vacuum_threshold')::int
             + current_setting('autovacuum_vacuum_scale_factor')::float8 * reltuples)::bigint
         as dead_tuples_to_trigger
from pg_class
where oid in ('inscription.inscription'::regclass, 'contact.prospectus'::regclass)
order by reltuples;

-- 4. fillfactor 50: the rewrite leaves half of each page empty. The next UPDATE puts each
-- new version on the page of the old one, and adds nothing to the index (HOT updates).
alter table outils.m03_facture set (fillfactor = 50);
vacuum full outils.m03_facture;
execute measure;
select pg_stat_force_next_flush();
select n_tup_upd, n_tup_hot_upd from pg_stat_user_tables
where relid = 'outils.m03_facture'::regclass \gset before_
update outils.m03_facture set relance = relance - 1;
select pg_stat_force_next_flush();
execute measure;
select n_tup_upd - :before_n_tup_upd as updated,
       n_tup_hot_upd - :before_n_tup_hot_upd as hot_updated
from pg_stat_user_tables
where relid = 'outils.m03_facture'::regclass;

deallocate measure;
drop table outils.m03_facture;

-- Transaction ids are 32-bit counters: VACUUM freezes old rows before the counter wraps
-- around. The age of the oldest unfrozen transaction id of this database:
select datname, age(datfrozenxid) as xid_age
from pg_database
where datname = current_database();
