#!/usr/bin/env bash
# ci: skip (throwaway container, runs on the host)
# Clip D4.4: a damaged index page, what sees it and what repairs it. Runs in a throwaway
# container pgd4-check (DOCKER=podman for Podman), removed at the end. The script stops the
# instance and writes 16 bytes of garbage in the middle of an index file, which is what a
# faulty disk or controller does. The lab is not touched.
set -euo pipefail
docker=${DOCKER:-docker}
$docker run --rm --name pgd4-check --user postgres --entrypoint bash \
    docker.io/pgvector/pgvector:pg18 -c '
set -e
export PATH=/usr/lib/postgresql/18/bin:$PATH
D=/tmp/check
start() { pg_ctl -D $D -l $D.log -o "-c listen_addresses= -k /tmp" -w start >/dev/null; }
psql() { command psql -h /tmp -U postgres -X "$@" 2>&1 || true; }
initdb -D $D -U postgres >/dev/null 2>&1
start
psql -q <<SQL
create extension amcheck;
create table md4_facture as select g as id, md5(g::text) as payload from generate_series(1, 100000) as g;
alter table md4_facture add primary key (id);
checkpoint;
SQL
file=$D/$(psql -At -c "select pg_relation_filepath('"'"'md4_facture_pkey'"'"')")
pg_ctl -D $D -m fast -w stop >/dev/null

echo "== 16 bytes overwritten in block 100 of the index file"
dd if=/dev/urandom of=$file bs=1 count=16 seek=$((100 * 8192 + 4000)) conv=notrunc status=none
start

echo "== a query that reads other pages: nothing to see"
psql -c "select payload from md4_facture where id = 5"
echo "== pg_amcheck, the command line client of amcheck, on every index of the database"
pg_amcheck -h /tmp -U postgres -d postgres 2>&1 | head -6 || true
echo "== a query that reads the damaged page, and the server log"
psql -c "explain (costs off) select count(*) from md4_facture where id between 1 and 100000"
psql -c "select count(*) from md4_facture where id between 1 and 100000"
grep -m 2 -E "checksum|invalid page" $D.log | cut -c 29- || true
echo "== the index rebuilt from the table, which is intact"
psql -c "reindex index concurrently md4_facture_pkey"
psql -c "select bt_index_check('"'"'md4_facture_pkey'"'"', heapallindexed => true)"
psql -c "select count(*) from md4_facture where id between 1 and 100000"
pg_ctl -D $D -m fast -w stop >/dev/null
'
