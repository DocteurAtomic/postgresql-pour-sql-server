#!/usr/bin/env bash
# Exercise D6, start: a primary to replicate. Runs on the host (DOCKER=podman for Podman).
# Starts pgd6-exercise-primary on the network pgd6-net, with the volume
# pgd6-exercise-primary-data, restores pachadataformation in it, and creates the role
# replicator (REPLICATION, password replication-demo) with its pg_hba.conf line. The lab is
# not touched. 9-stop.sh removes everything the exercise created.
set -euo pipefail
. "$(dirname "$0")/../../demos/module_d6/lib.sh"
p=pgd6-exercise-primary
start_primary $p
restore_db $p
sql $p -c "select current_setting('cluster_name') as name, pg_is_in_recovery() as in_recovery,
                  (select count(*) from pg_stat_replication) as standbys"
echo "Primary ready. Connect with: ${DOCKER:-docker} exec -it $p psql -U postgres -d pachadataformation"
