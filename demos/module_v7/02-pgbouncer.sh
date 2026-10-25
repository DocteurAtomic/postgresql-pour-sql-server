#!/usr/bin/env bash
# ci: skip (starts a PgBouncer container next to the lab container pgcourse, on the host)
# Clip V7.2: PgBouncer 1.26 in transaction mode, image edoburu/pgbouncer. The container joins the network
# namespace of pgcourse (--network container:pgcourse), so the scenes are played by psql
# and pgbench inside pgcourse, against 127.0.0.1:6432. The script removes the container.
#   DOCKER=podman ./demos/module_v7/02-pgbouncer.sh
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
dir=$(cd "$(dirname "$0")" && pwd)
name=pgc-v7-bouncer
image=docker.io/edoburu/pgbouncer:v1.26.1-p0
in_lab() { $docker exec -i pgcourse sh -c "$1"; }

$docker rm -f "$name" > /dev/null 2>&1 || true
trap '$docker rm -f "$name" > /dev/null 2>&1 || true' EXIT
# The configuration goes in through the environment: no volume to mount.
$docker run -d --name "$name" --network container:pgcourse \
    -e PGB_INI="$(sed "s/dbname=pachadataformation/dbname=$db/" "$dir/pgbouncer/pgbouncer.ini")" \
    --entrypoint sh "$image" -c \
    'printf "%s\n" "$PGB_INI" > /tmp/pgbouncer.ini && printf "\"postgres\" \"\"\n" > /tmp/userlist.txt && exec pgbouncer /tmp/pgbouncer.ini' > /dev/null
sleep 2
in_lab "pg_isready -h 127.0.0.1 -p 6432"

echo "=== 1. Twenty clients, two server connections"
in_lab "printf 'select pg_sleep(0.05);\n' > /tmp/mv7-sleep.sql"
in_lab "pgbench -h 127.0.0.1 -p 6432 -U postgres -n -f /tmp/mv7-sleep.sql -c 20 -T 6 '$db' 2>&1 | grep -E '^(number of clients|number of transactions actually|latency average|tps)'" &
sleep 3
in_lab "psql -h 127.0.0.1 -p 6432 -U postgres -X -d pgbouncer -A -c 'show pools'" \
    | cut -d'|' -f1-4,7 | grep -v -E '^(pgbouncer|\()' | column -t -s'|'
in_lab "psql -U postgres -X -d '$db' -c \"select count(*) as server_connections from pg_stat_activity where datname = '$db' and client_addr = '127.0.0.1' and backend_type = 'client backend' and pid <> pg_backend_pid()\""
wait

echo "=== 2. A connection per transaction, direct and through PgBouncer"
in_lab "printf 'select 1;\n' > /tmp/mv7-select1.sql"
for port in 5432 6432; do
    echo "port $port:"
    in_lab "pgbench -h 127.0.0.1 -p $port -U postgres -n -C -f /tmp/mv7-select1.sql -c 1 -T 5 '$db' 2>&1 | grep -E '^(latency average|average connection time|tps)'"
done
in_lab "rm -f /tmp/mv7-sleep.sql /tmp/mv7-select1.sql"

echo "=== 3. A SET seen by another client (pool pdf_one, one server connection)"
in_lab "psql -h 127.0.0.1 -p 6432 -U postgres -X -d pdf_one -c \"set work_mem = '256MB'\" -c 'select pg_backend_pid() as server_pid, current_setting(\$\$work_mem\$\$) as work_mem'"
in_lab "psql -h 127.0.0.1 -p 6432 -U postgres -X -d pdf_one -c 'select pg_backend_pid() as server_pid, current_setting(\$\$work_mem\$\$) as work_mem'"
echo "=== 4. SET LOCAL stays in its transaction"
in_lab "psql -h 127.0.0.1 -p 6432 -U postgres -X -d pdf_one -c 'reset work_mem' -c 'begin' -c \"set local work_mem = '256MB'\" -c 'commit'"
in_lab "psql -h 127.0.0.1 -p 6432 -U postgres -X -d pdf_one -c 'select pg_backend_pid() as server_pid, current_setting(\$\$work_mem\$\$) as work_mem'"
