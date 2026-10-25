-- ci: skip (reads the instance of the exercise, pgd7-exercise, before or after its upgrade)
-- Module D7 exercise: what the planner and the extensions look like on this instance.
select current_setting('server_version') as version,
       current_setting('data_checksums') as checksums,
       (select count(*) from inscription.facture) as factures,
       (select count(*) from pg_stats
        where schemaname not in ('pg_catalog', 'information_schema')) as pg_stats_rows,
       (select count(*) from pg_statistic_ext_data) as extended_stats_with_data,
       (select count(*) from pg_stat_user_tables where last_analyze is not null) as tables_analyzed,
       (select extversion from pg_extension where extname = 'pg_stat_statements') as pgss_version;

explain (analyze, timing off, summary off, buffers off)
select facturecd from inscription.facture where montantht = 2500 and montantttc = 2990;
