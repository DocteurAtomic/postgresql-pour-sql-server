#!/usr/bin/env bash
# Module D8 exercise, starting point. Runs on the host (DOCKER=podman for Podman); the lab is
# not touched. Starts pgd8-expg, an empty PostgreSQL 18 (database pachadata), and the SQL
# Server source:
#   - by default, pgd8-exsql, a SQL Server 2022 container (Developer edition, image
#     mcr.microsoft.com/mssql/server:2022-latest) where the public backup of
#     PachaDataFormation (2019) is downloaded, checked and restored;
#   - with MSSQL_CONTAINER=<name>, your own SQL Server container with PachaDataFormation.
# MSSQL_SA_PASSWORD is required: for pgd8-exsql, choose one that meets the SQL Server password
# policy (8 characters or more, three kinds of characters). 3-solution.sh removes it all.
set -euo pipefail
cd "$(dirname "$0")"
export MSSQL_CONTAINER=${MSSQL_CONTAINER:-pgd8-exsql}
. ../../demos/module_d8/lib.sh
bak_url='https://files.pachadata.com/public/api/raw?hash=detKgDWpmgcSvphD4YTPvQ&file=%2Fsample-databases%2FPachadataFormation%2FSqlServer%2FPachadataFormation2019.bak'
bak_sha256=2e51fa667286dbc7382dc1cd83ee459f3caf0991000b7314de273858bb3a1144
cache=${XDG_CACHE_HOME:-$HOME/.cache}/pgd8
bak=$cache/PachadataFormation2019.bak

$docker network inspect pgd8-exnet >/dev/null 2>&1 || $docker network create pgd8-exnet >/dev/null
start_pg pgd8-expg pgd8-exnet

if [ "$MSSQL_CONTAINER" = pgd8-exsql ]; then
    mkdir -p "$cache"
    [ -f "$bak" ] || curl -fsSL -o "$bak" "$bak_url"
    echo "$bak_sha256  $bak" | sha256sum -c --quiet
    $docker run -d --name pgd8-exsql --network pgd8-exnet -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD \
        -e MSSQL_MEMORY_LIMIT_MB=2048 mcr.microsoft.com/mssql/server:2022-latest >/dev/null
    for i in $(seq 1 90); do
        echo "SELECT 1" | MSSQL_DB=master mssql -b >/dev/null 2>&1 && break
        [ "$i" = 90 ] && { echo "pgd8-exsql did not start" >&2; exit 1; }
        sleep 2
    done
    $docker cp "$bak" pgd8-exsql:/var/opt/mssql/data/PachadataFormation2019.bak
    MSSQL_DB=master mssql -b <<'SQL' | tail -1
RESTORE DATABASE PachaDataFormation FROM DISK = '/var/opt/mssql/data/PachadataFormation2019.bak'
WITH MOVE 'PachaDataFormation' TO '/var/opt/mssql/data/PachaDataFormation.mdf',
     MOVE 'PachaDataFormation_log' TO '/var/opt/mssql/data/PachaDataFormation_log.ldf';
SQL
    $docker exec pgd8-exsql rm /var/opt/mssql/data/PachadataFormation2019.bak
fi
echo "SET NOCOUNT ON; SELECT CONVERT(varchar(20), SERVERPROPERTY('ProductVersion')) AS version,
      (SELECT COUNT(*) FROM Stage.Session) AS sessions;" | mssql
echo "Source: $MSSQL_CONTAINER (sqlcmd and bcp in /opt/mssql-tools18/bin). Target:"
echo "  $docker exec -it pgd8-expg psql -U postgres -d pachadata"
