#!/usr/bin/env bash
# Module D3 exercise, solution. Runs on the host after 1-start.sh (DOCKER=podman for
# Podman). Restores the nightly base backup in a new instance, pgd3-exercise-restore,
# replays the archive up to the minute before the mistake, checks the data, ends the
# recovery, then copies the prices back to pgd3-exercise. At the end it removes the two
# containers and their volumes (KEEP=1 to keep them).
set -euo pipefail
cd "$(dirname "$0")"
. ../../demos/module_d3/lib.sh
src=pgd3-exercise
dst=pgd3-exercise-restore
cleanup() {
    [ "${KEEP:-0}" = 1 ] && return
    $docker rm -f $src $dst >/dev/null 2>&1 || true
    $docker volume rm -f pgd3-exercise-archive pgd3-exercise-backup pgd3-exercise-data >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "== 1. the archive and the backup"
sql $src -c "select archived_count, last_archived_wal, failed_count from pg_stat_archiver"
$docker exec $src bash -c 'cat /backup/day.txt; grep -E "START TIME|LABEL" /backup/nightly/backup_label'

echo "== 2. the target: the minute that starts between the reminders and the mistake"
day=$($docker exec $src sed -n 's/^base backup: .*(\([0-9-]*\),.*/\1/p' /backup/day.txt)
minute=$($docker exec $src sed -n 's/^\([0-9:]*\)  the mistake.*/\1/p' /backup/day.txt | cut -c1-5)
target="$day $minute:00+00"
echo "recovery_target_time = '$target'"

echo "== 3. a new instance from the backup, recovery up to the target"
$docker volume create pgd3-exercise-data >/dev/null
fill_volume pgd3-exercise-backup nightly pgd3-exercise-data
$docker run --rm --user postgres -v pgd3-exercise-data:/var/lib/postgresql --entrypoint bash $image -c "
printf \"restore_command = 'cp /archive/wal/%%f %%p'\nrecovery_target_time = '$target'\n\" >> $pgdata/postgresql.conf
touch $pgdata/recovery.signal"
$docker run -d --name $dst -e POSTGRES_PASSWORD=course -v pgd3-exercise-archive:/archive:ro \
    -v pgd3-exercise-data:/var/lib/postgresql $image >/dev/null
wait_ready $dst
until [ "$(sql $dst -At -c "select pg_get_wal_replay_pause_state()")" = paused ]; do sleep 1; done
$docker logs $dst 2>&1 | grep -E "recovery stopping|pausing" | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //'

echo "== 4. paused: the restored instance, then the original one"
sql $dst -d pachadataformation < 2-check.sql
sql $src -d pachadataformation < 2-check.sql

echo "== 5. end the recovery"
sql $dst -At -c "select pg_wal_replay_resume()" >/dev/null
until [ "$(sql $dst -At -c "select pg_is_in_recovery()")" = f ]; do sleep 1; done
sql $dst -c "select timeline_id from pg_control_checkpoint()"

echo "== 6. bring the prices back to the original instance, without losing the rest"
sql $dst -d pachadataformation -c "\copy (select sessionid, prix from stage.session) to stdout" \
    | sql $src -d pachadataformation -v ON_ERROR_STOP=1 -c "
create temp table prix_before (sessionid int primary key, prix numeric(8,2));
copy prix_before from stdin;
update stage.session s set prix = p.prix from prix_before p where p.sessionid = s.sessionid;"
sql $src -d pachadataformation < 2-check.sql
