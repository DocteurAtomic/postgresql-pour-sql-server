-- ci: skip (changes the instance: ALTER SYSTEM RESET ALL)
-- Clip D1.2: undo every ALTER SYSTEM. postgresql.auto.conf is emptied; shared_buffers
-- goes back to 128MB only after a restart.
alter system reset all;
select pg_reload_conf();
\! sleep 1
select name, setting, unit, pending_restart
from pg_settings
where name in ('shared_buffers', 'work_mem')
order by name;
