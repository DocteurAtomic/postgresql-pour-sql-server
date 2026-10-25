#!/usr/bin/env bash
# Clip D8.2: tds_fdw, the foreign data wrapper for SQL Server, installed from the PGDG
# repository that the lab image declares (network needed). Runs on the host (DOCKER=podman for
# Podman), in a throwaway container pgd8-fdw on the network pgd8-net; both are removed at the
# end. Reads the SQL Server source described in lib.sh (MSSQL_SA_PASSWORD required).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
cleanup() {
    $docker rm -f -v pgd8-fdw >/dev/null 2>&1 || true
    $docker network rm pgd8-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
$docker network create pgd8-net >/dev/null
start_pg pgd8-fdw pgd8-net

echo "== 1. the package of the PGDG repository"
$docker exec pgd8-fdw bash -c 'apt-get update -qq >/dev/null 2>&1 &&
    apt-get install -y -qq postgresql-18-tds-fdw >/dev/null 2>&1 &&
    dpkg-query -W -f "\${Package} \${Version}\n" postgresql-18-tds-fdw'

echo "== 2. the foreign server, a foreign table, what goes to SQL Server"
$docker exec -i -e MSSQL_HOST -e MSSQL_PORT -e MSSQL_DB -e MSSQL_USER -e MSSQL_PASSWORD pgd8-fdw \
    psql -U postgres -d pachadata -X < "$here/02-tds-fdw.sql" 2>&1
