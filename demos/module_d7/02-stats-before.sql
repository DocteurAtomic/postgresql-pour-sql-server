-- ci: skip
-- Clip D7.2: run by 02-pg-upgrade.sh on the PostgreSQL 17 instance pgd7-old, before the
-- upgrade. Not for the lab: it creates an extended statistics object.
-- Montant HT and montant TTC are two columns that depend on each other: without extended
-- statistics the planner multiplies their selectivities and underestimates.
create statistics inscription.st_facture_montants (dependencies, mcv)
    on montantht, montantttc from inscription.facture;
analyze inscription.facture;

select version();
show data_checksums;

-- What the planner knows: per-column statistics, extended statistics.
select count(*) as pg_stats_rows,
       md5(string_agg(concat_ws('|', schemaname, tablename, attname, null_frac, n_distinct,
                                most_common_vals, most_common_freqs, histogram_bounds,
                                correlation), ',' order by schemaname, tablename, attname))
           as fingerprint
from pg_stats
where schemaname not in ('pg_catalog', 'information_schema');

select statistics_name, dependencies
from pg_stats_ext
where statistics_name = 'st_facture_montants';

explain (analyze, timing off, summary off, buffers off)
select facturecd from inscription.facture where montantht = 2500 and montantttc = 2990;

-- What the cumulative statistics system counted.
select relname, seq_scan, n_live_tup, last_analyze is not null as analyzed
from pg_stat_user_tables
where relname in ('facture', 'session')
order by relname;
