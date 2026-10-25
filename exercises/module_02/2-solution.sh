#!/usr/bin/env bash
# Module 2 exercise, solution: the processes and the files seen from the container.
# Runs on the host, against the lab container pgcourse (DOCKER=podman for Podman).
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
q() { $docker exec pgcourse psql -U postgres -d "$db" -XAt -c "$1"; }
# 1. Every process of the container: PID 1 is the postmaster.
$docker top pgcourse pid ppid args
# 2. The files of inscription.facture: the table, its fsm and vm, and its indexes.
pgdata=$(q "show data_directory")
for f in $(q "select pg_relation_filepath(oid) from pg_class
              where oid = 'inscription.facture'::regclass
                 or oid in (select indexrelid from pg_index
                            where indrelid = 'inscription.facture'::regclass)
              order by relkind desc, relname"); do
    $docker exec pgcourse sh -c "ls -l $pgdata/$f $pgdata/${f}_* 2>/dev/null || true"
done
