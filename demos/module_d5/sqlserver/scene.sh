#!/usr/bin/env bash
# Plays a scene of the module on SQL Server, several sqlcmd sessions in one command, on the
# host, against the container sql2022 (MSSQL=<container> otherwise, DOCKER=podman for
# Podman), in the database MD5PgMonitor of 00-setup.sql. The password of sa is read from
# SQLCMDPASSWORD, never written on the command line.
#   SQLCMDPASSWORD=... ./demos/module_d5/sqlserver/scene.sh 01a-report.sql 01b-app.sql ...
# Each session gets the host name md5-<name> (01b-app.sql gives md5-app), which the
# observer uses to find and KILL only the sessions of the scene. Each script starts one
# second after the previous one; the outputs are printed at the end, in order.
set -euo pipefail
docker=${DOCKER:-docker}
mssql=${MSSQL:-sql2022}
delay=${DELAY:-1}
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
n=0
for f in "$@"; do
    [ -f "$f" ] || f=$here/$f
    host=md5-$(basename "$f" .sql | cut -d- -f2-)
    [ $n -gt 0 ] && sleep "$delay"
    $docker exec -i -e SQLCMDPASSWORD="$SQLCMDPASSWORD" "$mssql" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -C -d MD5PgMonitor -W -s'|' -H "$host" < "$f" > "$tmp/$n.txt" 2>&1 &
    n=$((n + 1))
done
wait || true
n=0
for f in "$@"; do
    echo "=== session $(printf "\\x$(printf %x $((65 + n)))"): $(basename "$f")"
    cat "$tmp/$n.txt"
    n=$((n + 1))
done
