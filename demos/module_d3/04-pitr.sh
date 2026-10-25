#!/usr/bin/env bash
# Clip D3.4: WAL archiving and point-in-time recovery. Runs on the host (DOCKER=podman for
# Podman). pgd3-source archives its WAL to the volume pgd3-archive; a base backup goes to
# pgd3-backup; after a mistake, pgd3-restore starts from that backup and replays the
# archive up to a moment chosen before the mistake. Containers and volumes are removed at
# the end. The lab is not touched.
set -euo pipefail
cd "$(dirname "$0")"
. ./lib.sh
src=pgd3-source
dst=pgd3-restore
cleanup() {
    $docker rm -f $src $dst >/dev/null 2>&1 || true
    $docker volume rm -f pgd3-archive pgd3-backup pgd3-restore-data >/dev/null 2>&1 || true
}
trap cleanup EXIT
archive_command='test ! -f /archive/wal/%f && cp %p /archive/wal/%f'

# The archive directory has to exist, and belong to postgres, before the server tries to
# archive anything.
$docker volume create pgd3-archive >/dev/null
$docker run --rm -v pgd3-archive:/archive --entrypoint bash $image -c 'mkdir /archive/wal && chown postgres /archive/wal'
$docker run -d --name $src -e POSTGRES_PASSWORD=course -v pgd3-archive:/archive \
    -v pgd3-backup:/backup $image postgres -c archive_mode=on -c "archive_command=$archive_command" >/dev/null
wait_ready $src
$docker exec $src chown postgres /backup
restore_db $src

echo "== 1. archiving is on"
sql $src < 04-archive-settings.sql

echo "== 2. the base backup"
$docker exec --user postgres $src pg_basebackup -U postgres -D /backup/full -Fp -X stream -c fast -l "d3 before the mistake"
$docker exec $src grep -E "START (WAL|TIME)" /backup/full/backup_label

echo "== 3. a change, the target, the mistake"
out=$(sql $src -d pachadataformation -At < 04-workload.sql)
echo "$out"
target=$(echo "$out" | sed -n 's/^target //p')

echo "== 4. switch to a new WAL segment, so that the last one is archived"
last=$(sql $src -At -c "select pg_walfile_name(pg_current_wal_lsn())")
sql $src -At -c "select pg_switch_wal()" >/dev/null
until [ "$(sql $src -At -c "select last_archived_wal >= '$last' from pg_stat_archiver")" = t ]; do sleep 1; done
sql $src -c "select archived_count, last_archived_wal, failed_count from pg_stat_archiver"
$docker exec $src bash -c 'ls /archive/wal | tail -4; echo "$(ls /archive/wal | wc -l) files, $(du -sh /archive/wal | cut -f1)"'

echo "== 5. restore the base backup, ask for recovery up to $target"
$docker volume create pgd3-restore-data >/dev/null
fill_volume pgd3-backup full pgd3-restore-data
$docker run --rm --user postgres -v pgd3-restore-data:/var/lib/postgresql --entrypoint bash $image -c "
cat >> $pgdata/postgresql.conf <<CONF
restore_command = 'cp /archive/wal/%f %p'
recovery_target_time = '$target'
CONF
touch $pgdata/recovery.signal
tail -2 $pgdata/postgresql.conf; ls $pgdata | grep signal"
$docker run -d --name $dst -e POSTGRES_PASSWORD=course -v pgd3-archive:/archive:ro \
    -v pgd3-restore-data:/var/lib/postgresql $image >/dev/null
wait_ready $dst
until [ "$(sql $dst -At -c "select pg_get_wal_replay_pause_state()")" = paused ]; do sleep 1; done
$docker logs $dst 2>&1 | grep -E "starting point-in-time|restored log file|recovery stopping|pausing|consistent" \
    | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'

echo "== 6. paused at the target, read only: check before going on"
sql $dst -c "select pg_is_in_recovery() as in_recovery, pg_get_wal_replay_pause_state() as pause_state"
sql $dst -d pachadataformation < 04-check-restore.sql
sql $dst -d pachadataformation -c "create table outils.md3_test (id int)" 2>&1 || true
echo "-- the source, after the mistake"
sql $src -d pachadataformation < 04-check-restore.sql

echo "== 7. end the recovery: a new timeline"
sql $dst -At -c "select pg_wal_replay_resume()" >/dev/null
until [ "$(sql $dst -At -c "select pg_is_in_recovery()")" = f ]; do sleep 1; done
$docker logs $dst 2>&1 | grep -E "selected new timeline|archive recovery complete|ready to accept" | tail -3 \
    | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'
sql $dst -c "select timeline_id from pg_control_checkpoint()"
$docker exec $dst bash -c "ls $pgdata/pg_wal | grep -v -e archive_status -e summaries; cat $pgdata/pg_wal/00000002.history; ls $pgdata | grep -c signal || true"
