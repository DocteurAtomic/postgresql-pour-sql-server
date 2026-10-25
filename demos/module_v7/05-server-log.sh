#!/usr/bin/env bash
# ci: skip (pgbench in the lab container, then the container's log, from the host)
# Clip V7.5: log_min_duration_statement, set for one connection by PGOPTIONS. pgbench sends
# two parameterized queries with the extended protocol, as a driver does, psql one query
# with the simple protocol. The server log of the lab goes to the container's output.
#   DOCKER=podman ./demos/module_v7/05-server-log.sh
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
in_lab() { $docker exec -i pgcourse sh -c "$1"; }
since=$(date -u +%Y-%m-%dT%H:%M:%SZ)
sleep 1
in_lab "printf '\\\\set r 29\nselect count(*), sum(montantttc) from inscription.facture where relance = :r;\n\\\\set r 0\nselect count(*), sum(montantttc) from inscription.facture where relance = :r;\n' > /tmp/mv7-log.sql"
in_lab "PGOPTIONS='-c log_min_duration_statement=0' pgbench -U postgres -n -M extended -t 1 -f /tmp/mv7-log.sql '$db' 2>&1 | grep '^number of transactions actually'"
in_lab "PGOPTIONS='-c log_min_duration_statement=0' psql -U postgres -d '$db' -X -At -c 'select count(*) from inscription.facture where relance = 0'"
in_lab "rm -f /tmp/mv7-log.sql"
sleep 1
$docker logs --since "$since" pgcourse 2>&1 | grep -E 'duration:|DETAIL:  Parameters'
