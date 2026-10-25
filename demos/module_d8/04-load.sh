#!/usr/bin/env bash
# Clip D8.4: loading the data. pgloader for the training tables, then bcp and COPY for the
# table it cannot read, then ANALYZE. Runs on the host (DOCKER=podman for Podman), in a
# throwaway container pgd8-target on the network pgd8-net; both are removed at the end, as is
# the bcp file written in the SQL Server container. The instance runs with autovacuum off, so
# that the state of the statistics after the load does not depend on when autovacuum passes.
# Reads the SQL Server source described in lib.sh (MSSQL_SA_PASSWORD required).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
export_file=/tmp/pgd8_ville.tsv
cleanup() {
    $docker exec "$MSSQL_CONTAINER" rm -f $export_file >/dev/null 2>&1 || true
    $docker rm -f -v pgd8-target >/dev/null 2>&1 || true
    $docker network rm pgd8-net >/dev/null 2>&1 || true
}
trap cleanup EXIT
$docker network create pgd8-net >/dev/null
start_pg pgd8-target pgd8-net -c autovacuum=off
reset_db() { $docker exec pgd8-target bash -c 'dropdb -U postgres pachadata && createdb -U postgres pachadata'; }

echo "== 1. pgloader on the tables with a geography or geometry column"
pgloader pgd8-net 04-spatial.load 2>&1 | grep -E '^[0-9TZ:.-]+ (ERROR A thread|FATAL)' | sed -E 's/^[0-9TZ:.-]+ //' | sort -u || true
sql pgd8-target -c "select relname, n_live_tup from pg_stat_user_tables order by relname"
reset_db

echo "== 2. pgloader on the training tables"
pgloader pgd8-net 04-load.load > /tmp/pgd8-load.log 2>&1 || { cat /tmp/pgd8-load.log; exit 1; }
grep -E 'ERROR|WARNING|FATAL' /tmp/pgd8-load.log || echo "no error, no warning"
grep -E '^ +(stage\.session|inscription\.inscription|inscription\.facture|contact\.contact) |Create Indexes|Primary Keys|Create Foreign Keys|Reset Sequences|Total import time' /tmp/pgd8-load.log
rm -f /tmp/pgd8-load.log

echo "== 3. bcp out of SQL Server, COPY into PostgreSQL"
sql pgd8-target -q < "$here/04-ville.sql"
bcp_out "SELECT VilleId, RegionId, NomVille, CodePostal, CodeINSEE, CodeRegion, Latitude, Longitude,
                Eloignement, PointGeographique.STAsText(), PaysCD FROM Reference.ville" $export_file
$docker exec "$MSSQL_CONTAINER" bash -c "wc -l < $export_file; head -2 $export_file"
echo "-- COPY, text format"
$docker exec "$MSSQL_CONTAINER" cat $export_file \
    | sql pgd8-target -c "copy reference.ville from stdin" 2>&1 || true
echo "-- COPY, csv format with a tab delimiter"
$docker exec "$MSSQL_CONTAINER" cat $export_file \
    | sql pgd8-target -c "copy reference.ville from stdin (format csv, delimiter E'\t')"
sql pgd8-target -c "select count(*) as villes, count(latitude) as with_latitude,
                           count(pointgeographique) as with_point from reference.ville" \
    -c "alter table contact.adresse add constraint fk_adresse_reference_ville
            foreign key (villeid) references reference.ville (villeid)"

echo "== 4. the statistics after the load, then after ANALYZE"
sql pgd8-target < "$here/04-analyze.sql"
$docker exec pgd8-target vacuumdb -U postgres --analyze-only --quiet pachadata
sql pgd8-target < "$here/04-analyze.sql"
