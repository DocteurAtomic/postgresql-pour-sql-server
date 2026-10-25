-- ci: skip (exercise D6, runs on the standby)
-- The lag seen from the standby: what it received, what it replayed, and the commit time
-- of the last transaction replayed.
select pg_is_in_recovery() as in_recovery,
       pg_get_wal_replay_pause_state() as replay,
       pg_last_wal_receive_lsn() as received,
       pg_last_wal_replay_lsn() as replayed,
       pg_size_pretty(pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn())) as not_replayed,
       now() - pg_last_xact_replay_timestamp() as since_last_replayed_commit;
