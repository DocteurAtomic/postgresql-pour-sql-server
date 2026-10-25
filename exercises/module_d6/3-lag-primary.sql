-- ci: skip (exercise D6, runs on the primary)
-- The lag of each standby, seen from the primary: bytes not yet replayed, and the three
-- delays the standby reported last.
select application_name, state, sync_state,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as behind,
       write_lag, flush_lag, replay_lag
from pg_stat_replication;
select slot_name, active, wal_status,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as held
from pg_replication_slots;
