-- ci: skip (reads pgd1-exercise after its restart)
-- Module D1 exercise, solution, question 4: every value applied, and the memory budget.
select name, setting, unit, pending_restart
from pg_settings
where name in ('shared_buffers', 'max_connections', 'effective_cache_size', 'work_mem',
               'maintenance_work_mem', 'autovacuum_work_mem', 'log_min_duration_statement')
order by name;

select pg_size_pretty(pg_size_bytes(current_setting('shared_buffers'))) as shared_buffers,
       pg_size_pretty(current_setting('max_connections')::bigint
                      * pg_size_bytes(current_setting('work_mem'))) as one_sort_each,
       pg_size_pretty(current_setting('autovacuum_max_workers')::bigint
                      * pg_size_bytes(current_setting('autovacuum_work_mem'))) as autovacuum_at_most;
