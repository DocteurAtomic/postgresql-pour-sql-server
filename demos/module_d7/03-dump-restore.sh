#!/usr/bin/env bash
# Clip D7.3: the other path, dump and restore from 17 into 18, with the 18 pg_dumpall reading
# the 17 server over the network, then pg_upgrade --link on the same 17 instance, to compare.
# Runs on the host (DOCKER=podman for Podman), in throwaway containers pgd7-dump17,
# pgd7-dump18 and pgd7-dumpup, on the network pgd7-net; all are removed at the end, with
# their volumes. The lab is not touched. About 1 GB of disk while it runs.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
old=pgd7-dump17
new=pgd7-dump18
cleanup() {
    $docker rm -f -v $old $new pgd7-dumpup >/dev/null 2>&1 || true
    $docker volume rm -f pgd7-dump17 pgd7-dump18 >/dev/null 2>&1 || true
    $docker network rm pgd7-net >/dev/null 2>&1 || true
}
trap cleanup EXIT

$docker network create pgd7-net >/dev/null
$docker run -d --name $old --network pgd7-net -e POSTGRES_PASSWORD=course -e PGDATA=$pgdata17 \
    -v pgd7-dump17:/var/lib/postgresql $img17 >/dev/null
$docker run -d --name $new --network pgd7-net -e POSTGRES_PASSWORD=course \
    -v pgd7-dump18:/var/lib/postgresql $img18 >/dev/null
wait_ready $old
wait_ready $new
restore_db $old
# A second database, five million rows, so that the volume weighs in the comparison.
sql $old -q -c "create database volume"
sql $old -d volume -q -c "create table measure as
    select g as id, now() - g * interval '1 second' as taken_at, md5(g::text) as label
    from generate_series(1, 5000000) g" -c "alter table measure add primary key (id)"

echo "== 1. the two servers, and the size of the old one"
sql $old -At -c "select version()"
sql $new -At -c "select version()" -c "show data_checksums"
sql $old -c "select datname, pg_size_pretty(pg_database_size(datname)) as size
             from pg_database where datname in ('pachadataformation', 'volume') order by 1"

echo "== 2. pg_dumpall of 18, reading 17, piped into psql of 18"
$docker exec -e PGPASSWORD=course $new bash -c '
    TIMEFORMAT="dump and restore: %R s"
    time { pg_dumpall -h pgd7-dump17 -U postgres | psql -U postgres -X -q -o /dev/null 2>/tmp/errors.txt; }
    echo "errors: $(grep -c ERROR /tmp/errors.txt)"; grep ERROR /tmp/errors.txt'

echo "== 3. the restored database, and what the planner knows about it"
sql $new -d pachadataformation -c "select count(*) as factures from inscription.facture" \
    -c "select count(*) as pg_stats_rows from pg_stats
        where schemaname not in ('pg_catalog', 'information_schema')"

echo "== 4. pg_dump --statistics, for pachadataformation alone"
sql $new -q -c "drop database pachadataformation"
$docker exec -e PGPASSWORD=course $new bash -c '
    pg_dump -h pgd7-dump17 -U postgres -d pachadataformation --create --statistics \
        | psql -U postgres -X -q -o /dev/null 2>/dev/null'
sql $new -d pachadataformation -c "select count(*) as pg_stats_rows from pg_stats
                                    where schemaname not in ('pg_catalog', 'information_schema')"

echo "== 5. the same 17 instance, upgraded in place by pg_upgrade --link"
$docker stop -t 60 $old >/dev/null
start_new pgd7-dumpup pgd7-dump17
as_postgres pgd7-dumpup "initdb -D $pgdata18 -U postgres --no-data-checksums >/dev/null 2>&1
    export PGBINOLD=/usr/lib/postgresql/17/bin PGBINNEW=/usr/lib/postgresql/18/bin
    export PGDATAOLD=$pgdata17 PGDATANEW=$pgdata18
    TIMEFORMAT='pg_upgrade --link: %R s'; time pg_upgrade --link >/dev/null"
