-- Clip D1.3: the memory the settings allow, computed from pg_settings. Lab database,
-- psql. Read only.
select name, setting, unit, context
from pg_settings
where name in ('shared_buffers', 'effective_cache_size', 'work_mem', 'hash_mem_multiplier',
               'maintenance_work_mem', 'autovacuum_work_mem', 'autovacuum_max_workers',
               'max_connections', 'max_parallel_workers_per_gather')
order by name;

-- No global cap: every connection may sort once, hash twice as much, and so may its workers.
select current_setting('max_connections') as connections,
       current_setting('work_mem') as work_mem,
       pg_size_pretty(current_setting('max_connections')::bigint
                      * pg_size_bytes(current_setting('work_mem'))) as one_sort_each,
       pg_size_pretty(current_setting('max_connections')::bigint
                      * pg_size_bytes(current_setting('work_mem'))
                      * (1 + 2 * current_setting('hash_mem_multiplier')::numeric)) as one_sort_two_hashes_each;

-- Autovacuum workers take maintenance_work_mem each, unless autovacuum_work_mem is set.
select current_setting('autovacuum_max_workers') as workers,
       current_setting('maintenance_work_mem') as maintenance_work_mem,
       pg_size_pretty(current_setting('autovacuum_max_workers')::bigint
                      * pg_size_bytes(current_setting('maintenance_work_mem'))) as autovacuum_at_most;
