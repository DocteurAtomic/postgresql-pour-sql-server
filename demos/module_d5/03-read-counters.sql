-- ci: skip (read by 03-cumulative-stats.sh in the container pgd5-stats)
-- Clip D5.3: the counters of the database and of one table, and when they were reset.
\pset null '-'
select datname, xact_commit, xact_rollback, blks_read, blks_hit, tup_inserted,
       temp_files, deadlocks, stats_reset
from pg_stat_database
where datname = current_database();
select relname, seq_scan, idx_scan, n_tup_ins, n_tup_upd, n_live_tup, n_dead_tup,
       last_analyze is not null as analyzed
from pg_stat_user_tables
where relid = 'inscription.facture'::regclass;
select pg_postmaster_start_time()::time(0) as server_started,
       (select min(stats_reset) from pg_stat_io)::time(0) as io_stats_reset;
