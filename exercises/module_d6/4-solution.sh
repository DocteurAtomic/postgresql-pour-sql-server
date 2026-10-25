#!/usr/bin/env bash
# Exercise D6, solution: plays the four questions from scratch, then removes the containers,
# volumes and network (KEEP=1 to keep them). Runs on the host (DOCKER=podman for Podman).
# The lab is not touched.
set -euo pipefail
ex=$(cd "$(dirname "$0")" && pwd)
. "$ex/../../demos/module_d6/lib.sh"
p=pgd6-exercise-primary
s=pgd6-exercise-standby
[ "${KEEP:-0}" = 1 ] || trap '"$ex/9-stop.sh" >/dev/null' EXIT
"$ex/1-start.sh" >/dev/null

echo "== 1. clone the primary with pg_basebackup -R, a slot, and start the standby"
$docker volume create $s-data >/dev/null
$docker run --rm --network $net --user postgres -e PGPASSWORD=$reppass \
    -v $s-data:/var/lib/postgresql --entrypoint bash $image -c "
    mkdir -p $(dirname $pgdata)
    pg_basebackup -h $p -U replicator -D $pgdata -R -C -S standby1 -X stream -c fast
    chmod 700 $pgdata
    ls $pgdata | grep signal; grep -o 'primary_slot_name.*' $pgdata/postgresql.auto.conf"
$docker run -d --name $s --hostname $s --network $net -e POSTGRES_PASSWORD=course \
    -v $s-data:/var/lib/postgresql $image postgres -c cluster_name=$s >/dev/null
wait_ready $s

echo "== 2. both sides"
sql $p < "$ex/3-lag-primary.sql"
sql $s < "$ex/3-lag-standby.sql"

echo "== 3. replay paused on the standby, a burst of writes on the primary"
sql $s -At -c "select pg_wal_replay_pause()" >/dev/null
until [ "$(sql $s -At -c "select pg_get_wal_replay_pause_state()")" = paused ]; do sleep 0.5; done
sql $p -d pachadataformation -q < "$ex/2-load.sql"
sleep 2
sql $p < "$ex/3-lag-primary.sql"
sql $s < "$ex/3-lag-standby.sql"
sql $s -d pachadataformation -c "select to_regclass('outils.md6x_load') as load_table"
echo "-- replay resumed"
sql $s -At -c "select pg_wal_replay_resume()" >/dev/null
wait_replayed $p $s
sql $p < "$ex/3-lag-primary.sql"
sql $s -d pachadataformation -c "select count(*) as load_rows from outils.md6x_load"

echo "== 4. promote the standby"
$docker exec --user postgres $p pg_ctl stop -D $pgdata -m fast >/dev/null 2>&1 || true
$docker wait $p >/dev/null 2>&1 || true
sql $s -c "select pg_promote()"
sql $s -q -c "checkpoint"
sql $s -c "select pg_is_in_recovery() as in_recovery,
                  (select timeline_id from pg_control_checkpoint()) as timeline"
sql $s -d pachadataformation -c "update stage.session set prix = prix + 10 where sessionid = 40"
echo "-- the old primary, started again on its own: its slot is now orphaned"
$docker start $p >/dev/null
wait_ready $p
sql $p < "$ex/3-lag-primary.sql"
sql $p -c "select pg_drop_replication_slot('standby1')"
$docker exec --user postgres $p pg_ctl stop -D $pgdata -m fast >/dev/null 2>&1 || true
