-- ci: skip (changes the instance: ALTER SYSTEM RESET ALL; meant for pgd1-exercise)
-- Module D1 exercise, solution, question 5: undo, and see what still waits for a restart.
alter system reset all;
select pg_reload_conf();
\! sleep 1
select name, setting, unit, pending_restart
from pg_settings
where name in ('shared_buffers', 'max_connections', 'work_mem', 'log_min_duration_statement')
order by pending_restart desc, name;
