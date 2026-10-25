-- Clip D1.4: where the server log goes, and what it records by default. Lab database,
-- psql. Read only.
select name, setting, unit, context
from pg_settings
where name in ('logging_collector', 'log_destination', 'log_directory', 'log_filename',
               'log_line_prefix', 'log_min_duration_statement', 'log_lock_waits',
               'log_autovacuum_min_duration', 'log_checkpoints', 'log_connections',
               'log_min_messages', 'deadlock_timeout')
order by name;

-- Without the logging collector there is no log file to read from SQL.
select pg_current_logfile() as current_log_file;
