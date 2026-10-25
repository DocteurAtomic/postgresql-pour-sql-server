-- Clip D4.1: the autovacuum settings, the thresholds of each table, and the per-table
-- settings. Lab database, psql, after 00-setup.sql. One session; it changes only the
-- table outils.md4_journal, which it creates and drops.

-- 1. The global settings, with the context that says when a change takes effect.
select name, setting, unit, context
from pg_settings
where name in ('autovacuum', 'autovacuum_naptime', 'autovacuum_max_workers',
               'autovacuum_worker_slots', 'autovacuum_vacuum_threshold',
               'autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_max_threshold',
               'autovacuum_vacuum_insert_threshold', 'autovacuum_vacuum_insert_scale_factor',
               'autovacuum_analyze_threshold', 'autovacuum_analyze_scale_factor',
               'autovacuum_vacuum_cost_delay', 'autovacuum_vacuum_cost_limit',
               'vacuum_cost_limit', 'log_autovacuum_min_duration')
order by name;

-- 2. The three thresholds of the largest tables, from pg_class.reltuples, against the
-- counters that pg_stat_user_tables keeps since the last VACUUM or ANALYZE.
select s.relname, c.reltuples::bigint as rows,
       s.n_dead_tup as dead,
       least(current_setting('autovacuum_vacuum_max_threshold')::bigint,
             current_setting('autovacuum_vacuum_threshold')::int
             + current_setting('autovacuum_vacuum_scale_factor')::float8 * c.reltuples)::bigint
         as vacuum_at,
       s.n_ins_since_vacuum as inserted,
       (current_setting('autovacuum_vacuum_insert_threshold')::int
        + current_setting('autovacuum_vacuum_insert_scale_factor')::float8 * c.reltuples
          * (1 - c.relallfrozen::float8 / greatest(c.relpages, 1)))::bigint as insert_vacuum_at,
       s.n_mod_since_analyze as modified,
       (current_setting('autovacuum_analyze_threshold')::int
        + current_setting('autovacuum_analyze_scale_factor')::float8 * c.reltuples)::bigint
         as analyze_at
from pg_stat_user_tables as s
join pg_class as c on c.oid = s.relid
order by c.reltuples desc
limit 5;

-- 3. A table that receives many writes gets its own thresholds, as storage parameters.
-- 1 % of the rows instead of 20 %, and every autovacuum of the table in the server log.
drop table if exists outils.md4_journal;
create table outils.md4_journal as
select g as id, now() - g * interval '1 minute' as logged_at, md5(g::text) as payload
from generate_series(1, 200000) as g;
alter table outils.md4_journal set (autovacuum_vacuum_scale_factor = 0.01,
                                    autovacuum_vacuum_threshold = 1000,
                                    log_autovacuum_min_duration = 0);
analyze outils.md4_journal;
select relname, reloptions from pg_class where reloptions is not null and relkind = 'r';

-- The threshold of this table, its storage parameters first, the global setting otherwise.
with opts as (
    select c.oid, c.reltuples,
           (select split_part(o, '=', 2) from unnest(c.reloptions) as o
            where o like 'autovacuum_vacuum_scale_factor=%')::float8 as scale_factor,
           (select split_part(o, '=', 2) from unnest(c.reloptions) as o
            where o like 'autovacuum_vacuum_threshold=%')::int as threshold
    from pg_class as c
    where c.oid = 'outils.md4_journal'::regclass
)
select oid::regclass as table_name, reltuples::bigint as rows,
       (coalesce(threshold, current_setting('autovacuum_vacuum_threshold')::int)
        + coalesce(scale_factor, current_setting('autovacuum_vacuum_scale_factor')::float8)
          * reltuples)::bigint as vacuum_at,
       (current_setting('autovacuum_vacuum_threshold')::int
        + current_setting('autovacuum_vacuum_scale_factor')::float8 * reltuples)::bigint
         as vacuum_at_with_global_settings
from opts;

-- 4. The vacuum counters of the table, including the time columns added in 18.
select relname, last_vacuum, last_autovacuum, vacuum_count, autovacuum_count,
       last_analyze, last_autoanalyze, total_autovacuum_time, total_autoanalyze_time
from pg_stat_user_tables
where relid = 'outils.md4_journal'::regclass;

drop table outils.md4_journal;
