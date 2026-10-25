#!/usr/bin/env bash
# Clip D7.1: a minor upgrade is a binary swap, a major one is refused on the same files.
# Runs on the host (DOCKER=podman for Podman), in throwaway containers on the volumes
# pgd7-minor and pgd7-major; all are removed at the end. Pulls postgres:18.4 (an older minor
# of 18) the first time; the lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
img184=docker.io/library/postgres:18.4
cleanup() {
    $docker rm -f -v pgd7-minor pgd7-major pgd7-major18 >/dev/null 2>&1 || true
    $docker volume rm -f pgd7-minor pgd7-major >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "== 1. an instance created by 18.4"
$docker pull -q $img184 >/dev/null
$docker run -d --name pgd7-minor -e POSTGRES_PASSWORD=course -v pgd7-minor:/var/lib/postgresql $img184 >/dev/null
wait_ready pgd7-minor
sql pgd7-minor -c "create table minor_test as select g as id from generate_series(1, 1000) g" -q
sql pgd7-minor -At -c "select version()" -c "show server_version_num"

echo "== 2. the same files, started by 18.6"
$docker stop -t 60 pgd7-minor >/dev/null
$docker rm -v pgd7-minor >/dev/null
$docker run -d --name pgd7-minor -e POSTGRES_PASSWORD=course -v pgd7-minor:/var/lib/postgresql $img18 >/dev/null
wait_ready pgd7-minor
sql pgd7-minor -At -c "select version()" -c "show server_version_num" -c "select count(*) from minor_test"

echo "== 3. an instance created by 17"
$docker run -d --name pgd7-major -e POSTGRES_PASSWORD=course -e PGDATA=$pgdata17 \
    -v pgd7-major:/var/lib/postgresql $img17 >/dev/null
wait_ready pgd7-major
sql pgd7-major -At -c "select version()"
$docker exec pgd7-major cat $pgdata17/PG_VERSION
$docker stop -t 60 pgd7-major >/dev/null
$docker rm -v pgd7-major >/dev/null

echo "== 4. the 17 files, started by 18"
$docker run --name pgd7-major18 --user postgres -v pgd7-major:/var/lib/postgresql \
    --entrypoint postgres $img18 -D $pgdata17 2>&1 | sed -E 's/^[0-9-]+ [0-9:.]+ UTC \[[0-9]+\] //' || true

echo "== 5. what pg_control says: catalog version of each major"
$docker run --rm --user postgres -v pgd7-major:/var/lib/postgresql --entrypoint pg_controldata $img17 $pgdata17 \
    | grep -E "pg_control version|Catalog version|Data page checksum"
$docker run --rm --user postgres -v pgd7-minor:/var/lib/postgresql --entrypoint pg_controldata $img18 $pgdata18 \
    | grep -E "pg_control version|Catalog version|Data page checksum" || true
