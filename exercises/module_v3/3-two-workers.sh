#!/usr/bin/env bash
# ci: skip (two concurrent workers, on the host, against the lab container pgcourse)
# Module V3 exercise, solution: two workers empty the queue at the same time, with
# SKIP LOCKED, then without any lock on the read. After each run, the checks: invoices
# processed, log rows, invoices logged twice. Ends with 4-cleanup.sql.
#   DOCKER=podman ./exercises/module_v3/3-two-workers.sh
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
dir=$(dirname "$0")
psql_run() { $docker exec -i pgcourse sh -c "psql -U postgres -d '$db' -X -q -v ON_ERROR_STOP=1 2>&1"; }

checks() {
    psql_run <<'SQL'
select worker, count(*) as invoices from outils.mv3_invoice_queue group by worker order by worker;
select count(*) as log_rows, count(distinct facturecd) as distinct_invoices,
       count(*) - count(distinct facturecd) as processed_twice
from outils.mv3_invoice_log;
SQL
}

run() {   # run SKIP_LOCKED
    psql_run < "$dir/1-setup.sql" > /dev/null
    psql_run <<< "call outils.mv3_invoice_worker('A', 10, $1);" &
    psql_run <<< "call outils.mv3_invoice_worker('B', 10, $1);" &
    wait
    checks
}

psql_run < "$dir/2-worker.sql"
echo "=== with FOR UPDATE SKIP LOCKED"
run true
echo "=== without any lock on the read"
run false
psql_run < "$dir/4-cleanup.sql"
