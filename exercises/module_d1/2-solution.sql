-- ci: skip (changes the instance: ALTER SYSTEM, reload; meant for pgd1-exercise)
-- Module D1 exercise, solution, questions 2 and 3. Run in the exercise container:
--   docker exec -i pgd1-exercise psql -U postgres -X < exercises/module_d1/2-solution.sql
-- 3-reset.sql undoes it.

-- 2. Before changing anything: the context of each setting tells which ones need a restart.
select name, setting, unit, context
from pg_settings
where name in ('shared_buffers', 'max_connections', 'effective_cache_size', 'work_mem',
               'maintenance_work_mem', 'autovacuum_work_mem', 'log_min_duration_statement')
order by context, name;

-- 3. Starting values for a dedicated instance with 4 GB of memory.
alter system set shared_buffers = '1GB';            -- 25 % of the memory
alter system set max_connections = 50;              -- fewer processes, a pooler in front
alter system set effective_cache_size = '3GB';      -- shared_buffers plus the system cache
alter system set work_mem = '16MB';                 -- 50 x 16 MB for one sort each: 800 MB
alter system set maintenance_work_mem = '256MB';    -- VACUUM, CREATE INDEX
alter system set autovacuum_work_mem = '128MB';     -- 3 autovacuum workers: 384 MB at most
alter system set log_min_duration_statement = '500ms';
select pg_reload_conf();
\! sleep 1
select name, setting, unit, context, pending_restart
from pg_settings
where name in ('shared_buffers', 'max_connections', 'effective_cache_size', 'work_mem',
               'maintenance_work_mem', 'autovacuum_work_mem', 'log_min_duration_statement')
order by pending_restart desc, name;
