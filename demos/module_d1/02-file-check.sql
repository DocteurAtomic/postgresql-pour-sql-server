-- ci: skip (reads the throwaway container of 02-alter-system.sh, after a hand edit)
-- Clip D1.2: check the configuration files before a reload or a restart.
select sourcefile, sourceline, name, setting, applied, error
from pg_file_settings
where name in ('shared_buffers', 'shared_bufers', 'work_mem')
order by seqno;
