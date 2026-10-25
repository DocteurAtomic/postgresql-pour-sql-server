-- ci: skip
-- Clip D7.2: run by 02-pg-upgrade.sh on the upgraded instance (pgd7-new, PostgreSQL 18),
-- once right after pg_upgrade, once after vacuumdb. Read only.
select version();
show data_checksums;

select count(*) as pg_stats_rows,
       md5(string_agg(concat_ws('|', schemaname, tablename, attname, null_frac, n_distinct,
                                most_common_vals, most_common_freqs, histogram_bounds,
                                correlation), ',' order by schemaname, tablename, attname))
           as fingerprint
from pg_stats
where schemaname not in ('pg_catalog', 'information_schema');

-- The statistics object is there, its data is not.
select s.stxname, d.stxddependencies is not null as has_data
from pg_statistic_ext s
left join pg_statistic_ext_data d on d.stxoid = s.oid
where s.stxname = 'st_facture_montants';

explain (analyze, timing off, summary off, buffers off)
select facturecd from inscription.facture where montantht = 2500 and montantttc = 2990;

select relname, seq_scan, n_live_tup, last_analyze is not null as analyzed
from pg_stat_user_tables
where relname in ('facture', 'session')
order by relname;
