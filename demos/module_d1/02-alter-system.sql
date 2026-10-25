-- ci: skip (changes the instance: ALTER SYSTEM, configuration reload)
-- Clip D1.2: ALTER SYSTEM, pg_reload_conf() and pending_restart. Recorded in the throwaway
-- container of 02-alter-system.sh. On your lab: run it with psql, then 02-reset.sql and
-- "docker compose restart db" to undo it. Some statements fail on purpose: no ON_ERROR_STOP.

-- SET changes a setting for this session only, and only if its context allows it.
set shared_buffers = '1GB';

-- ALTER SYSTEM writes postgresql.auto.conf. Nothing changes yet.
alter system set shared_buffers = '1GB';
alter system set work_mem = '16MB';
alter system set shared_bufers = '1GB';        -- a typo is refused at once

-- Reload: what the context allows is applied, the rest waits for a restart.
select pg_reload_conf();
\! sleep 1
select name, setting, unit, context, pending_restart
from pg_settings
where name in ('shared_buffers', 'work_mem')
order by name;

select sourcefile, name, setting, applied, error
from pg_file_settings
where name in ('shared_buffers', 'work_mem')
order by seqno;
