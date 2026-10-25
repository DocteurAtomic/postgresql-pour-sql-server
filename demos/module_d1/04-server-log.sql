-- ci: skip (changes the instance: ALTER SYSTEM, configuration reload)
-- Clip D1.4: what to log. Recorded in the throwaway container of 04-server-log.sh. On your
-- lab: run it, then 04-reset.sql to undo it.
alter system set log_line_prefix = '%m [%p] %q%u@%d %a ';
alter system set log_min_duration_statement = '250ms';
alter system set log_lock_waits = on;
alter system set log_autovacuum_min_duration = '1s';
select pg_reload_conf();
\! sleep 1
select name, setting, unit, context
from pg_settings
where name in ('log_line_prefix', 'log_min_duration_statement', 'log_lock_waits',
               'log_autovacuum_min_duration')
order by name;
