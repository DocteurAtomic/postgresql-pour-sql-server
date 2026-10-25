-- ci: skip (changes the instance: ALTER SYSTEM RESET ALL)
-- Clip D1.4: undo the logging settings; logging_collector goes back after a restart.
alter system reset all;
select pg_reload_conf();
\! sleep 1
select name, setting, pending_restart
from pg_settings
where name in ('logging_collector', 'log_min_duration_statement', 'log_lock_waits')
order by name;
