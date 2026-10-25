#!/usr/bin/env bash
# Clip D8.6: the cutover. Freezing the writes on SQL Server (in a database of the module), the
# identity left behind by the load, its reset, and a rehearsal that measures the whole window.
# Runs on the host (DOCKER=podman for Podman), in a throwaway container pgd8-target on the
# network pgd8-net; both are removed at the end. Reads the SQL Server source described in
# lib.sh; sqlserver/06-freeze.sql creates and drops MD8PgCutover.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
work=$(mktemp -d)
cleanup() {
    rm -rf "$work"
    $docker rm -f -v pgd8-target >/dev/null 2>&1 || true
    $docker network rm pgd8-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
ms() { date +%s%N | cut -c1-13; }

echo "== 1. freezing the writes on SQL Server"
mssql < "$here/sqlserver/06-freeze.sql" 2>&1

echo "== 2. the rehearsal: load, validation, identities"
$docker network create pgd8-net >/dev/null
start_pg pgd8-target pgd8-net
t0=$(ms)
load_training pgd8-target pgd8-net
load_ville pgd8-target
t1=$(ms)
mssql -h -1 < "$here/sqlserver/05-profile.sql" | sort > "$work/sqlserver.txt"
sql pgd8-target -At < "$here/05-profile.sql" | sort > "$work/postgresql.txt"
diff "$work/sqlserver.txt" "$work/postgresql.txt" && echo "profile: $(wc -l < "$work/postgresql.txt") lines, no difference"
t2=$(ms)
echo "load: $((t1 - t0)) ms, validation: $((t2 - t1)) ms"

echo "== 3. the first INSERT after the load"
sql pgd8-target < "$here/06-insert.sql" 2>&1
sql pgd8-target < "$here/06-identities.sql"

echo "== 4. the identity columns of SQL Server, added to the tables of pgloader"
mssql -h -1 < "$here/sqlserver/06-identity-ddl.sql" > "$work/identities.sql"
head -3 "$work/identities.sql"
t3=$(ms)
sql pgd8-target -q -v ON_ERROR_STOP=1 < "$work/identities.sql"
sql pgd8-target < "$here/06-insert.sql" 2>&1
sql pgd8-target < "$here/06-identities.sql"

echo "== 5. the sequences moved past the largest values"
sql pgd8-target -q < "$here/06-reset-identities.sql" > /dev/null
t4=$(ms)
sql pgd8-target < "$here/06-identities.sql"
sql pgd8-target < "$here/06-insert.sql" 2>&1
echo "identities: $((t4 - t3)) ms; window of the rehearsal: $(( (t1 - t0) + (t2 - t1) + (t4 - t3) )) ms"
