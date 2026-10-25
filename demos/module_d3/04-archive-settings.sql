-- ci: skip (reads the throwaway instance pgd3-source of 04-pitr.sh, where archiving is on)
-- Clip D3.4: the settings of WAL archiving and what the archiver has done so far.
select name, setting, context
from pg_settings
where name in ('wal_level', 'archive_mode', 'archive_command', 'archive_timeout')
order by name;

select archived_count, last_archived_wal, failed_count
from pg_stat_archiver;
