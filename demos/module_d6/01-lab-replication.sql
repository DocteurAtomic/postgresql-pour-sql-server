-- Clip D6.1: what the lab instance is ready for. Lab database, psql, read only.
-- The settings are instance-wide: replication sends the WAL of the whole instance.
select name, setting, context
from pg_settings
where name in ('wal_level', 'max_wal_senders', 'max_replication_slots', 'hot_standby',
               'synchronous_standby_names', 'synchronous_commit')
order by name;

-- A primary on its own: not in recovery, no standby connected, no slot.
select pg_is_in_recovery() as in_recovery,
       (select count(*) from pg_stat_replication) as standbys,
       (select count(*) from pg_replication_slots) as slots;
