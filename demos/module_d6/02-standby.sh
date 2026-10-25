#!/usr/bin/env bash
# Clip D6.2: building a standby with pg_basebackup -R, watching it, and what its physical
# slot does to the primary's WAL. Runs on the host (DOCKER=podman for Podman). pgd6-primary
# keeps max_wal_size at 128MB, so that the WAL held for the slot shows above it; pgd6-standby
# is cloned into the volume pgd6-standby-data by a throwaway container on pgd6-net.
# Containers, volumes and the network are removed at the end. The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
p=pgd6-primary
s=pgd6-standby
trap 'cleanup $p $s' EXIT
start_primary $p -c max_wal_size=128MB
restore_db $p

# write_wal <table>: about 160 MB of WAL on the primary, a table of 300,000 wide rows.
write_wal() {
    sql $p -d pachadataformation -q -c "create table outils.$1 as
        select g, repeat('x', 500) as filler from generate_series(1, 300000) g"
}
wal_dir() {
    sql $p -c "select count(*) as wal_files, pg_size_pretty(sum(size)) as wal_size,
                      current_setting('max_wal_size') as max_wal_size from pg_ls_waldir()"
}
slots() {
    sql $p -c "select slot_name, active, wal_status,
                      pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as held
               from pg_replication_slots"
}

echo "== 1. on the primary: a role with REPLICATION, a replication line in pg_hba.conf"
sql $p -c "select rolname, rolreplication, rolsuper from pg_roles where rolname = 'replicator'"
sql $p -c "select type, database, user_name, address, auth_method
           from pg_hba_file_rules where 'replication' = any(database)"

echo "== 2. pg_basebackup -R -C -S standby1, from a container on the network"
$docker volume create $s-data >/dev/null
$docker run --rm --network $net --user postgres -e PGPASSWORD=$reppass \
    -v $s-data:/var/lib/postgresql --entrypoint bash $image -c "
    mkdir -p $(dirname $pgdata)
    pg_basebackup -h $p -U replicator -D $pgdata -R -C -S standby1 -X stream -c fast -P 2>&1 \
        | tr '\r' '\n' | tail -1
    chmod 700 $pgdata
    ls $pgdata | grep -E 'signal|backup_label'
    echo '--- postgresql.auto.conf'
    grep -v '^#' $pgdata/postgresql.auto.conf | sed -E 's/ channel_binding=.*target_session_attrs=any/ .../'"
slots

echo "== 3. the standby starts on the copy"
$docker run -d --name $s --hostname $s --network $net -e POSTGRES_PASSWORD=course \
    -v $s-data:/var/lib/postgresql $image \
    postgres -c shared_preload_libraries=pg_stat_statements -c cluster_name=$s >/dev/null
wait_ready $s
logs $s | grep -E 'entering standby mode|redo starts|consistent recovery|read-only connections|started streaming'
sql $p -x -c "select application_name, client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
                     write_lag, flush_lag, replay_lag, sync_state
              from pg_stat_replication"
sql $s -x -c "select status, sender_host, slot_name, flushed_lsn, latest_end_time
              from pg_stat_wal_receiver"

echo "== 4. the lag, sampled while the primary writes 160 MB of WAL"
write_wal md6_load &
for i in 1 2 3 4; do
    sleep 0.5
    sql $p -At -F ' | ' -c "select clock_timestamp()::time(1),
            pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as behind,
            write_lag, replay_lag from pg_stat_replication"
done
wait
wait_replayed $p $s
sql $p -c "select pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) as behind,
                  replay_lag from pg_stat_replication"

echo "== 5. the standby stops; the slot keeps its WAL"
$docker stop $s >/dev/null
write_wal md6_while_down
sql $p -q -c "checkpoint"
slots
wal_dir

echo "== 6. the standby comes back and catches up; the WAL is released"
$docker start $s >/dev/null
wait_ready $s
wait_replayed $p $s
sql $p -q -c "checkpoint" -c "select pg_switch_wal()" -c "checkpoint" >/dev/null
slots
wal_dir

echo "== 7. max_slot_wal_keep_size = 64MB, the standby stops again"
sql $p -At -c "alter system set max_slot_wal_keep_size = '64MB'" -c "select pg_reload_conf()" >/dev/null
$docker stop $s >/dev/null
write_wal md6_while_down_again
sql $p -q -c "checkpoint"
sql $p -c "select slot_name, active, wal_status, restart_lsn, invalidation_reason from pg_replication_slots"
logs $p | grep -A1 'invalidating obsolete replication slot'
t=$(date -u +%FT%TZ)
$docker start $s >/dev/null
sleep 5
logs $s $t | grep -A1 -E 'can no longer access' | head -2
