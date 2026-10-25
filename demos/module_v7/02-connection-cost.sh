#!/usr/bin/env bash
# ci: skip (pgbench, run inside the lab container pgcourse from the host)
# Clip V7.2: what a connection costs. pgbench runs "select 1" for five seconds on one
# client, first on a single connection, then with a new connection for each transaction
# (-C). It connects through the Unix socket, where the lab asks for no password.
#   DOCKER=podman ./demos/module_v7/02-connection-cost.sh
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
in_lab() { $docker exec -i pgcourse sh -c "$1"; }

in_lab "printf 'select 1;\n' > /tmp/mv7-select1.sql"
echo "=== One connection for the whole run"
in_lab "pgbench -U postgres -n -f /tmp/mv7-select1.sql -c 1 -T 5 '$db' 2>&1 | grep -E '^(number of transactions actually|latency average|initial connection time|tps)'"
echo "=== A new connection for each transaction (-C)"
in_lab "pgbench -U postgres -n -C -f /tmp/mv7-select1.sql -c 1 -T 5 '$db' 2>&1 | grep -E '^(number of transactions actually|latency average|average connection time|tps)'"
in_lab "rm -f /tmp/mv7-select1.sql"
