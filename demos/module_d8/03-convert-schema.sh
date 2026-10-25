#!/usr/bin/env bash
# Clip D8.3: converting the schema of the training tables with pgloader, schema only, in three
# attempts. Runs on the host (DOCKER=podman for Podman), in a throwaway container pgd8-schema
# on the network pgd8-net; both are removed at the end. Reads the SQL Server source described
# in lib.sh (MSSQL_SA_PASSWORD required). The lab is not touched.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
cleanup() {
    $docker rm -f -v pgd8-schema >/dev/null 2>&1 || true
    $docker network rm pgd8-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
$docker network create pgd8-net >/dev/null
start_pg pgd8-schema pgd8-net
reset_db() { $docker exec pgd8-schema bash -c 'dropdb -U postgres pachadata && createdb -U postgres pachadata'; }

echo "== 1. pgloader $($docker run --rm $pgloader_image pgloader --version | head -1 | cut -d'"' -f2), default casting rules"
pgloader pgd8-net 01-default.load 2>&1 | grep -E 'ERROR|FATAL|HINT|suser_sname' | sed -E 's/^[0-9TZ:.-]+ //' || true

echo "== 2. the T-SQL function created first, default casting rules"
reset_db
pgloader pgd8-net 02-schema.load 2>&1 | grep -E 'ERROR|FATAL|Create tables|Primary Keys|Foreign Keys|Reset Sequences' || true
sql pgd8-schema < "$here/03-schema-review.sql"

echo "== 3. casting rules that keep lengths and precisions"
reset_db
pgloader pgd8-net 03-cast.load 2>&1 | grep -E 'ERROR|FATAL|Create tables|Primary Keys|Foreign Keys' || true
sql pgd8-schema < "$here/03-schema-review.sql"
sql pgd8-schema -c '\df public.*'

echo "== 4. a table of dbo: its identity column becomes a serial"
reset_db
pgloader pgd8-net 03-dbo.load 2>&1 | grep -E 'ERROR|FATAL|Create tables|Reset Sequences' || true
sql pgd8-schema -c '\d dbo.boucletest'
