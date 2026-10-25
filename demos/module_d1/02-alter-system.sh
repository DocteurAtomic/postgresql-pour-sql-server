#!/usr/bin/env bash
# Clip D1.2: ALTER SYSTEM, reload, restart, and a typo in postgresql.conf.
# Runs on the host, in a throwaway container pgd1-conf with its volume pgd1-conf-data
# (DOCKER=podman for Podman); both are removed at the end. The lab is not touched.
set -euo pipefail
cd "$(dirname "$0")"
docker=${DOCKER:-docker}
name=pgd1-conf
image=docker.io/pgvector/pgvector:pg18
conf=/var/lib/postgresql/18/docker/postgresql.conf
cleanup() { $docker rm -f $name >/dev/null 2>&1; $docker volume rm -f $name-data >/dev/null 2>&1; }
trap cleanup EXIT
wait_ready() { until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done; }
run() { $docker exec -i $name sh -c 'psql -U postgres -X 2>&1' < "$1"; }

$docker run -d --name $name -e POSTGRES_PASSWORD=course -v $name-data:/var/lib/postgresql $image >/dev/null
wait_ready

echo "== ALTER SYSTEM and reload"
run 02-alter-system.sql
echo "== postgresql.auto.conf"
$docker exec $name cat /var/lib/postgresql/18/docker/postgresql.auto.conf

echo "== restart"
$docker restart $name >/dev/null; wait_ready
run 02-after-restart.sql

echo "== a hand edit of postgresql.conf, with a typo"
$docker exec $name sh -c "printf '# added by hand\nwork_mem = 32MB\nshared_bufers = 1GB\n' >> $conf"
run 02-file-check.sql
$docker exec $name psql -U postgres -X -q -c "select pg_reload_conf()" -c "select pg_sleep(1)" >/dev/null
$docker logs --since 5s $name 2>&1 | grep -E "in file|postgresql\.conf\" contains" || true
$docker exec $name psql -U postgres -X -At -c "show work_mem"

echo "== restart with the typo"
$docker restart $name >/dev/null || true
sleep 3
$docker ps -a --filter name=$name --format '{{.Status}}'
$docker logs --tail 2 $name 2>&1

echo "== repair the file from another container, start, undo ALTER SYSTEM"
$docker run --rm -v $name-data:/var/lib/postgresql --entrypoint sed $image -i '/^# added by hand/,$d' $conf
$docker start $name >/dev/null; wait_ready
run 02-reset.sql
