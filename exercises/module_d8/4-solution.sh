#!/usr/bin/env bash
# Module D8 exercise, solution. Runs on the host (DOCKER=podman for Podman) after 1-start.sh,
# with the same MSSQL_SA_PASSWORD (and MSSQL_CONTAINER if you used your own source). Migrates
# Stage.Session into pgd8-expg by bcp and COPY, compares the two profiles, then fixes the
# identity. At the end, removes the containers and the network of the exercise (KEEP=1 to
# keep them); the downloaded backup stays in ~/.cache/pgd8.
set -euo pipefail
cd "$(dirname "$0")"
export MSSQL_CONTAINER=${MSSQL_CONTAINER:-pgd8-exsql}
. ../../demos/module_d8/lib.sh
work=$(mktemp -d)
cleanup() {
    rm -rf "$work"
    $docker exec "$MSSQL_CONTAINER" rm -f /tmp/pgd8_session_raw.tsv /tmp/pgd8_session.tsv >/dev/null 2>&1 || true
    [ -n "${KEEP:-}" ] && return
    $docker rm -f -v pgd8-expg pgd8-exsql >/dev/null 2>&1 || true
    $docker network rm pgd8-exnet >/dev/null 2>&1 || true
}
trap cleanup EXIT
target() { $docker exec -i pgd8-expg psql -U postgres -d pachadata -X "$@"; }

echo "== 1. the source table"
mssql < 2-inventory.sql

echo "== 2. the target table"
target -q < 4-target.sql
target -c '\d stage.session'

echo "== 3. bcp with a tab delimiter, COPY in csv format"
bcp_out "SELECT * FROM Stage.Session" /tmp/pgd8_session_raw.tsv
$docker exec "$MSSQL_CONTAINER" cat /tmp/pgd8_session_raw.tsv \
    | target -c "copy stage.session from stdin (format csv, delimiter E'\t')" 2>&1 || true

echo "== 4. bcp of a query that writes the text format of COPY: \\N, \\r, \\n, \\\\"
bcp_out "SELECT SessionId, StageId, LangueCd, ISNULL(CONVERT(varchar(11), SalleFormationId), '\N'),
                DateDebut, ISNULL(CONVERT(varchar(12), Prix), '\N'), ISNULL(CONVERT(varchar(3), Note), '\N'),
                ISNULL(CONVERT(varchar(10), Statut), '\N'), DateCreation,
                ISNULL(CONVERT(varchar(3), Duree), '\N'), IntraEntrerprise,
                ISNULL(REPLACE(REPLACE(REPLACE(Remarques, '\', '\\'), CHAR(13), '\r'), CHAR(10), '\n'), '\N'),
                ISNULL(CONVERT(varchar(11), FormateurId), '\N')
         FROM Stage.Session" /tmp/pgd8_session.tsv
$docker exec "$MSSQL_CONTAINER" cat /tmp/pgd8_session.tsv | target -c "copy stage.session from stdin"
target -c "analyze stage.session"

echo "== 5. the profiles of both sides"
mssql -h -1 < 3-profile-mssql.sql | sort > "$work/sqlserver.txt"
target -At < 4-profile-pg.sql | sort > "$work/postgresql.txt"
cat "$work/postgresql.txt"
diff "$work/sqlserver.txt" "$work/postgresql.txt" && echo "no difference"

echo "== 6. new sessions written by the application"
target -c "insert into stage.session (stageid, languecd, datedebut)
           values (1, 'FR', date '2027-01-11') returning sessionid"
target -c "insert into stage.session (stageid, languecd, datedebut)
           select 1, 'FR', date '2027-01-11' + g from generate_series(1, 50) g" 2>&1 || true
target -c "delete from stage.session where datedebut >= date '2027-01-11' and stageid = 1 and remarques is null
           and sessionid < 40"
echo "SET NOCOUNT ON; SELECT IDENT_CURRENT('Stage.Session') AS ident_current;" | mssql
target -c "select setval(pg_get_serial_sequence('stage.session', 'sessionid'),
                         (select max(sessionid) from stage.session))" \
       -c "insert into stage.session (stageid, languecd, datedebut)
           values (1, 'FR', date '2027-01-11') returning sessionid"
