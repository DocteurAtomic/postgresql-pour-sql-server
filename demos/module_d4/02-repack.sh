#!/usr/bin/env bash
# ci: skip (throwaway container, runs on the host)
# Clip D4.2: VACUUM FULL against pg_repack, with a writer that inserts a row every 0.2 s.
# Runs in a throwaway container pgd4-repack (DOCKER=podman for Podman), removed at the end:
# the image of the lab plus the package postgresql-18-repack, installed at start from the
# PGDG repository the image already declares; it needs network access. The lab is not touched.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgd4-repack
image=docker.io/pgvector/pgvector:pg18
cleanup() { $docker rm -f $name >/dev/null 2>&1; }
trap cleanup EXIT
sql() { $docker exec -i $name sh -c 'psql -U postgres -X -v ON_ERROR_STOP=1 2>&1'; }

$docker run -d --name $name -e POSTGRES_PASSWORD=course --entrypoint bash $image -c '
    apt-get update -qq >/dev/null && apt-get install -y -qq postgresql-18-repack >/dev/null
    exec docker-entrypoint.sh postgres' >/dev/null
until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 2; done
sleep 2

bloat() {
sql <<'SQL'
drop table if exists md4_events;
create table md4_events (id bigint generated always as identity primary key,
                         created_at timestamptz not null default now(), payload text not null);
insert into md4_events (payload) select repeat(md5(g::text), 4) from generate_series(1, 5000000) as g;
delete from md4_events where id % 5 not in (0, 1);
vacuum md4_events;
select pg_size_pretty(pg_total_relation_size('md4_events')) as total_size, count(*) as rows from md4_events;
SQL
}
# The writer: 40 inserts, one every 0.2 s, each in its own connection; prints the slowest.
writer() {
    $docker exec $name bash -c '
        max=0
        for i in $(seq 1 40); do
            s=$(date +%s%N)
            psql -U postgres -X -q -c "insert into md4_events (payload) values ('\''writer'\'')"
            d=$(( ($(date +%s%N) - s) / 1000000 ))
            [ $d -gt $max ] && max=$d
            sleep 0.2
        done
        echo "writer: 40 inserts, slowest ${max} ms"'
}

echo "== pg_repack, installed as an extension of the database"
sql <<'SQL'
create extension pg_repack;
select extname, extversion from pg_extension where extname = 'pg_repack';
SQL

echo "== a table with three rows out of five deleted, then VACUUM FULL while the writer runs"
bloat
writer & wpid=$!
sleep 1
sql <<'SQL'
\timing on
vacuum full md4_events;
\timing off
select pg_size_pretty(pg_total_relation_size('md4_events')) as total_size;
SQL
wait $wpid

echo "== the same table bloated again, then pg_repack while the writer runs"
bloat
writer & wpid=$!
sleep 1
$docker exec $name bash -c 's=$(date +%s); pg_repack -U postgres -d postgres --table md4_events 2>&1; echo "pg_repack: $(( $(date +%s) - s )) s"'
sql <<'SQL'
select pg_size_pretty(pg_total_relation_size('md4_events')) as total_size;
SQL
wait $wpid
