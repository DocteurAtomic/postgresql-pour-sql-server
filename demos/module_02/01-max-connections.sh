#!/usr/bin/env bash
# Clip 2.1: what happens when every connection slot is taken.
# Runs on the host, in a throwaway container pgc-02-connections started with
# max_connections = 5 (DOCKER=podman for Podman). It removes the container at the end.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgc-02-connections
$docker run -d --rm --name $name -e POSTGRES_PASSWORD=course \
    docker.io/pgvector/pgvector:pg18 postgres -c max_connections=5 >/dev/null
trap '$docker stop $name >/dev/null' EXIT
until $docker exec $name pg_isready -U postgres -q; do sleep 1; done
sleep 2
# Five sessions that wait twenty seconds each.
for i in 1 2 3 4 5; do
    $docker exec $name psql -U postgres -X -q -c "select pg_sleep(20)" >/dev/null &
done
sleep 3
$docker exec $name psql -U postgres -X -c \
    "select count(*) as client_backends from pg_stat_activity where backend_type = 'client backend'" \
    || true
wait
