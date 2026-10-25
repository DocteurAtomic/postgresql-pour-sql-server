-- ci: skip (reads the throwaway container of 02-alter-system.sh after its restart)
-- Clip D1.2: after the restart, the postmaster setting is applied.
select name, setting, unit, source, pending_restart
from pg_settings
where name in ('shared_buffers', 'work_mem')
order by name;
