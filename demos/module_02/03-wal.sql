-- Clip 2.3: the WAL and the checkpoints. Lab database, psql, after 00-setup.sql.
-- It runs CHECKPOINT, which acts on the whole instance: play it on your own lab only.
-- (Recorded on a dedicated container, pgc-02-arch, restored like the lab.)

-- One WAL for the whole instance, every database included.
select name, setting, unit, context
from pg_settings
where name in ('wal_level', 'wal_segment_size', 'checkpoint_timeout', 'max_wal_size',
               'min_wal_size', 'checkpoint_completion_target', 'full_page_writes')
order by name;

select count(*) as wal_files, pg_size_pretty(sum(size)) as wal_size
from pg_ls_waldir();

select pg_current_wal_lsn() as current_lsn,
       pg_walfile_name(pg_current_wal_lsn()) as current_wal_file;

-- The checkpoints since the statistics were reset: on schedule, or requested.
select num_timed, num_requested, buffers_written, stats_reset::date
from pg_stat_checkpointer;

-- Full page writes: the first change of a page after a checkpoint writes the whole page.
-- fillfactor 50 leaves room on each page for the new row versions; VACUUM sets the
-- hint bits now, so that the measured UPDATE is the first change of each page.
create table outils.m02_wal with (fillfactor = 50) as
select inscriptionid, sessionid, remise from inscription.inscription;
vacuum outils.m02_wal;
select pg_relation_size('outils.m02_wal') / current_setting('block_size')::int as pages;

checkpoint;
select pg_current_wal_lsn() as lsn_start \gset
update outils.m02_wal set remise = remise + 1 where inscriptionid % 10 = 0;
select pg_current_wal_lsn() as lsn_first \gset
update outils.m02_wal set remise = remise - 1 where inscriptionid % 10 = 0;
select pg_current_wal_lsn() as lsn_second \gset

-- The same UPDATE twice: only the first one comes after the checkpoint.
select 'first update' as statement,
       count(*) as wal_records,
       count(*) filter (where fpi_length > 0) as with_full_page,
       pg_size_pretty(sum(fpi_length)) as full_pages,
       pg_size_pretty(pg_wal_lsn_diff(:'lsn_first', :'lsn_start')) as wal_written
from pg_get_wal_records_info(:'lsn_start', :'lsn_first')
union all
select 'second update', count(*), count(*) filter (where fpi_length > 0),
       pg_size_pretty(sum(fpi_length)),
       pg_size_pretty(pg_wal_lsn_diff(:'lsn_second', :'lsn_first'))
from pg_get_wal_records_info(:'lsn_first', :'lsn_second');

drop table outils.m02_wal;
