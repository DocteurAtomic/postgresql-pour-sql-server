#!/usr/bin/env bash
# Module D7 exercise, solution. Runs on the host (DOCKER=podman for Podman), after
# 1-start.sh. Stops pgd7-exercise, upgrades its data directory from 17 to 18 with
# pg_upgrade --link in a second container, pgd7-exercise-18 (the 18 image plus the 17
# binaries), on the same volume, then removes the containers and the volume (KEEP=1 to keep
# them).
set -euo pipefail
cd "$(dirname "$0")"
. ../../demos/module_d7/lib.sh
cleanup() {
    if [ "${KEEP:-0}" = 1 ]; then return; fi
    $docker rm -f -v pgd7-exercise pgd7-exercise-18 >/dev/null 2>&1 || true
    $docker volume rm -f pgd7-exercise >/dev/null 2>&1 || true
}
trap cleanup EXIT
upgrade="export PGBINOLD=/usr/lib/postgresql/17/bin PGBINNEW=/usr/lib/postgresql/18/bin
         export PGDATAOLD=$pgdata17 PGDATANEW=$pgdata18"

echo "== 1. the instance before the upgrade"
sql pgd7-exercise -d pachadataformation < 2-check.sql

echo "== 2. stop 17, a container with the binaries of both versions"
$docker stop -t 60 pgd7-exercise >/dev/null
start_new pgd7-exercise-18 pgd7-exercise
$docker exec pgd7-exercise-18 ls /usr/lib/postgresql

echo "== 3. initdb, then pg_upgrade --check"
as_postgres pgd7-exercise-18 "initdb -D $pgdata18 -U postgres >/dev/null 2>&1
    $upgrade; pg_upgrade --check --link | tail -2" || true
as_postgres pgd7-exercise-18 "rm -rf $pgdata18; initdb -D $pgdata18 -U postgres --no-data-checksums >/dev/null 2>&1
    $upgrade; pg_upgrade --check --link | tail -2"

echo "== 4. pg_upgrade --link"
as_postgres pgd7-exercise-18 "$upgrade; pg_upgrade --link > /tmp/upgrade.log; sed -n '/^Upgrade Complete/,\$p' /tmp/upgrade.log
    grep -A3 'extension updates' /tmp/upgrade.log; ls"

echo "== 5. start 18, the instance after the upgrade"
as_postgres pgd7-exercise-18 "pg_ctl -D $pgdata18 -l /var/lib/postgresql/18.log -w start >/dev/null"
sql pgd7-exercise-18 -d pachadataformation < 2-check.sql

echo "== 6. what pg_upgrade asked for"
as_postgres pgd7-exercise-18 "vacuumdb -U postgres --all --analyze-in-stages --missing-stats-only --quiet
    vacuumdb -U postgres --all --analyze-only --quiet
    psql -X -q -f update_extensions.sql postgres"
sql pgd7-exercise-18 -d pachadataformation < 2-check.sql

echo "== 7. can the old instance start again?"
as_postgres pgd7-exercise-18 "ls 17/docker/global | grep pg_control"
