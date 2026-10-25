#!/usr/bin/env bash
# Module D7 exercise, starting point. Runs on the host (DOCKER=podman for Podman); the lab is
# not touched. Starts pgd7-exercise, a PostgreSQL 17 instance whose data directory is in the
# volume pgd7-exercise (/var/lib/postgresql/17/docker), restores pachadataformation in it,
# adds an extended statistics object and the pg_stat_statements extension, then runs a few
# queries. 2-solution.sh removes it all.
set -euo pipefail
cd "$(dirname "$0")"
. ../../demos/module_d7/lib.sh
start_old pgd7-exercise pgd7-exercise
restore_db pgd7-exercise
sql pgd7-exercise -d pachadataformation -q -v ON_ERROR_STOP=1 <<'SQL'
create extension pg_stat_statements;
create statistics inscription.st_facture_montants (dependencies, mcv)
    on montantht, montantttc from inscription.facture;
analyze inscription.facture;
select count(*) from inscription.facture where montantht = 2500 and montantttc = 2990;
select count(*) from stage.session where prix > 3000;
SQL
sql pgd7-exercise -At -c "select version()"
echo "pgd7-exercise is running. Connect with: $docker exec -it pgd7-exercise psql -U postgres -d pachadataformation"
