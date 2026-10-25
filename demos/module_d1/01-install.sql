-- Clip D1.1: what initdb decided for the lab instance. Lab database, psql. Read only.
-- Where the instance keeps its files: the official image puts everything in PGDATA.
select name, setting
from pg_settings
where name in ('data_directory', 'config_file', 'hba_file', 'ident_file')
order by name;

-- Decided once, by initdb: checksums, encoding, block size, WAL segment size.
select name, setting, context
from pg_settings
where name in ('data_checksums', 'server_encoding', 'block_size', 'wal_segment_size')
order by name;

-- The locale of each database: provider c (libc), i (ICU) or b (builtin).
select datname, datlocprovider, datcollate, datlocale
from pg_database
where datname in ('postgres', 'template0', 'template1', 'pachadataformation')
order by datname;
