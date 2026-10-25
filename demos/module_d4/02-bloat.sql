-- Clip D4.2: measuring bloat with pgstattuple, then getting the space back. Lab database,
-- psql, after 00-setup.sql. One session; it creates outils.md4_facture (the 16,514
-- invoices copied 30 times, 495,420 rows) and drops it at the end.
drop table if exists outils.md4_facture;
create table outils.md4_facture as
select (row_number() over (order by f.facturecd, g))::int as id, f.*
from inscription.facture as f cross join generate_series(1, 30) as g;
alter table outils.md4_facture add primary key (id);
create index md4_facture_datefacture on outils.md4_facture (datefacture);
vacuum analyze outils.md4_facture;

-- The measure, used after each step: sizes, and what pgstattuple and pgstatindex read.
prepare measure as
select pg_size_pretty(pg_relation_size('outils.md4_facture')) as table_size,
       t.tuple_percent as live_pct, t.dead_tuple_percent as dead_pct, t.free_percent as free_pct,
       pg_size_pretty(pg_relation_size('outils.md4_facture_pkey')) as pkey_size,
       i.avg_leaf_density as pkey_leaf_density,
       pg_size_pretty(pg_relation_size('outils.md4_facture_datefacture')) as date_idx_size
from pgstattuple('outils.md4_facture') as t,
     pgstatindex('outils.md4_facture_pkey') as i;
execute measure;

-- 1. Four rows out of five deleted, everywhere in the table, as a purge would do.
delete from outils.md4_facture where id % 5 <> 0;
execute measure;

-- 2. VACUUM: the dead tuples are gone, their space is free inside the files.
vacuum outils.md4_facture;
execute measure;

-- pgstattuple reads every page. pgstattuple_approx skips the all-visible pages, using
-- the visibility map, and estimates them from the free space map.
select pg_size_pretty(table_len) as table_size, round(scanned_percent::numeric, 2) as scanned_pct,
       approx_tuple_count,
       round(approx_free_percent::numeric, 1) as approx_free_pct
from pgstattuple_approx('outils.md4_facture');

-- 3. The indexes: REINDEX CONCURRENTLY builds a new copy, then swaps it in.
reindex index concurrently outils.md4_facture_pkey;
reindex index concurrently outils.md4_facture_datefacture;
execute measure;

-- 4. The table: VACUUM FULL writes a new file, under an ACCESS EXCLUSIVE lock (clip 3.5
-- showed it on a smaller table); it rebuilds the indexes too.
vacuum full outils.md4_facture;
execute measure;

deallocate measure;
drop table outils.md4_facture;
