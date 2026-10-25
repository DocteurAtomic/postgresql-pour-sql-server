#!/usr/bin/env bash
# ci: skip (starts a PostgreSQL 17 container of its own)
# Clip V4.5: the query of 05-multicolumn-skip-scan.sql on PostgreSQL 17, which has no skip
# scan. Plays on the host, in a throwaway container pgc-v4-pg17 (image postgres:17), on a
# table of three million rows with the same index (present, datecreation) and the same
# creation times as outils.mv4_inscription. DOCKER=podman for Podman. Removes the
# container at the end.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgc-v4-pg17
$docker rm -f "$name" >/dev/null 2>&1 || true
$docker run -d --name "$name" -e POSTGRES_HOST_AUTH_METHOD=trust docker.io/library/postgres:17 >/dev/null
trap '$docker rm -f "$name" >/dev/null' EXIT
until $docker exec "$name" pg_isready -U postgres -h 127.0.0.1 >/dev/null 2>&1; do sleep 1; done
$docker exec -i "$name" sh -c 'psql -U postgres -X -e 2>&1' <<'EOF'
select version();
create table t as
select n, n % 4 = 0 as present,
       timestamp '2017-01-01 08:00' + n * interval '100 seconds' as datecreation
from generate_series(1, 3013164) as n;
create index t_present_date on t (present, datecreation);
vacuum analyze t;
explain (analyze, buffers)   -- BUFFERS is not shown by default before 18
select count(*)
from t
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-03-02';
-- The index alone, the table scan forbidden.
set enable_seqscan = off;
explain (analyze, buffers)   -- BUFFERS is not shown by default before 18
select count(*)
from t
where datecreation >= timestamp '2026-03-01' and datecreation < timestamp '2026-03-02';
EOF
