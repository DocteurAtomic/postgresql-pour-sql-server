#!/usr/bin/env bash
# Clip D1.4: the server log, on stderr then in files. Runs on the host, in a throwaway
# container pgd1-log with its volume pgd1-log-data (DOCKER=podman for Podman); both are
# removed at the end. The lab is not touched.
set -euo pipefail
cd "$(dirname "$0")"
docker=${DOCKER:-docker}
name=pgd1-log
image=docker.io/pgvector/pgvector:pg18
cleanup() { $docker rm -f $name >/dev/null 2>&1; $docker volume rm -f $name-data >/dev/null 2>&1; }
trap cleanup EXIT
wait_ready() { until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done; }
run() { $docker exec -i $name sh -c 'psql -U postgres -X 2>&1' < "$1"; }

$docker run -d --name $name -e POSTGRES_PASSWORD=course -v $name-data:/var/lib/postgresql $image >/dev/null
wait_ready
$docker exec $name psql -U postgres -X -q -c \
    "create table d1_account (id int primary key, balance int); insert into d1_account values (1, 100)"

echo "== what to log"
run 04-server-log.sql
mark=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "== a slow statement, then a lock wait (two sessions)"
run 04-slow-query.sql
run 04-lock-holder.sql >/dev/null &
sleep 1
run 04-lock-waiter.sql
wait
echo "== $docker logs --since $mark"
$docker logs --since "$mark" $name 2>&1

echo "== logging collector, after a restart"
run 04-collector.sql
$docker restart $name >/dev/null; wait_ready
$docker logs --tail 2 $name 2>&1
run 04-slow-query.sql >/dev/null
run 04-read-log.sql

echo "== undo"
run 04-reset.sql
