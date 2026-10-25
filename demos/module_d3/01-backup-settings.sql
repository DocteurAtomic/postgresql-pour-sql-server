-- Clip D3.1: what the lab instance is set up to do for backups. Lab database, psql, read only.
-- One set of settings for the whole instance: there is no recovery model per database.
select name, setting, context
from pg_settings
where name in ('wal_level', 'archive_mode', 'archive_command', 'archive_library',
               'summarize_wal', 'max_wal_senders')
order by name;

-- The archiver has never run on the lab.
select archived_count, failed_count, last_archived_wal
from pg_stat_archiver;

-- What a physical backup of the instance would contain: every database.
select datname, pg_size_pretty(pg_database_size(oid)) as size
from pg_database
order by oid;
