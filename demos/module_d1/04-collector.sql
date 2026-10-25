-- ci: skip (changes the instance: logging_collector needs a restart)
-- Clip D1.4: the logging collector writes files in PGDATA/log. Restart after this script.
alter system set logging_collector = on;
select pg_reload_conf();
\! sleep 1
select name, setting, pending_restart from pg_settings where name = 'logging_collector';
