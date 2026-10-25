#!/usr/bin/env bash
# Clip 2.4: a table larger than 1 GB is split into 1 GB segments.
# Runs on the host, in a throwaway container pgc-02-segments (DOCKER=podman for Podman):
# it writes about 1.4 GB, then removes the container.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgc-02-segments
$docker run -d --rm --name $name -e POSTGRES_PASSWORD=course \
    docker.io/pgvector/pgvector:pg18 >/dev/null
trap '$docker stop $name >/dev/null' EXIT
until $docker exec $name pg_isready -U postgres -q; do sleep 1; done
sleep 2
q() { $docker exec $name psql -U postgres -XAt -c "$1"; }
q "create table big as select g as id, repeat('x', 1000) as pad from generate_series(1, 1200000) as g" >/dev/null
q "select pg_size_pretty(pg_relation_size('big'))"
file=$(q "select pg_relation_filepath('big')")
pgdata=$(q "show data_directory")
$docker exec $name sh -c "ls -l $pgdata/$file*"
