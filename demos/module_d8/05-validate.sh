#!/usr/bin/env bash
# Clip D8.5: validating the load. The same profile of four tables computed by SQL Server and
# by PostgreSQL, compared line by line; then a silent rounding that the profile catches, and
# four checks that do not compare across engines. Runs on the host (DOCKER=podman for
# Podman), in a throwaway container pgd8-target on the network pgd8-net, loaded as 04-load.sh
# does; both are removed at the end. Reads the SQL Server source described in lib.sh.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
work=$(mktemp -d)
cleanup() {
    rm -rf "$work"
    $docker rm -f -v pgd8-target >/dev/null 2>&1 || true
    $docker network rm pgd8-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
$docker network create pgd8-net >/dev/null
start_pg pgd8-target pgd8-net
load_training pgd8-target pgd8-net
load_ville pgd8-target

profile() {
    mssql -h -1 < "$here/sqlserver/05-profile.sql" | sort > "$work/sqlserver.txt"
    sql pgd8-target -At < "$here/05-profile.sql" | sort > "$work/postgresql.txt"
    echo "lines: SQL Server $(wc -l < "$work/sqlserver.txt"), PostgreSQL $(wc -l < "$work/postgresql.txt")"
    diff "$work/sqlserver.txt" "$work/postgresql.txt" && echo "no difference"
}

echo "== 1. the profile on both sides"
grep -E '^stage\.session\|(prix|statut|datedebut|intraentrerprise)\|' <(sql pgd8-target -At < "$here/05-profile.sql")
profile

echo "== 2. a scale too small: PostgreSQL rounds without an error"
sql pgd8-target -c "alter table reference.ville alter column latitude type numeric(5,1)" \
    -c "select count(latitude) from reference.ville"
profile || true

echo "== 3. checks that compare representations, not data"
mssql < "$here/sqlserver/05-pitfalls.sql"
sql pgd8-target < "$here/05-pitfalls.sql"
