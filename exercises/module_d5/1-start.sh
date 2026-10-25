#!/usr/bin/env bash
# Module D5 exercise, starting point. Runs on the host (DOCKER=podman for Podman), against
# the lab container pgcourse (DB=<database> for another database than pachadataformation).
# Creates the table outils.md5_exercise, then leaves six sessions in the background, named
# by their application_name: some work, some wait. None lasts more than ten minutes.
# Run it again to start over; 3-reset.sql removes the table and what is left of the scene.
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
psql_lab() { $docker exec -i pgcourse psql -U postgres -d "$db" -X -q -v ON_ERROR_STOP=1 "$@"; }
# background <application_name> <shell command run in the container>
background() { $docker exec -d -e PGAPPNAME="$1" pgcourse sh -c "$2" > /dev/null; }
psql="psql -U postgres -d $db -X -q"

psql_lab < "$(dirname "$0")/3-reset.sql" > /dev/null
psql_lab <<'SQL'
create table outils.md5_exercise as
select sessionid, stageid, datedebut, prix from stage.session;
alter table outils.md5_exercise add primary key (sessionid);
SQL

background crm "(echo \"begin; update outils.md5_exercise set prix = prix where sessionid = 40;\"; sleep 600; echo 'commit;') | $psql"
sleep 1
background export "$psql -c 'select pg_sleep(600)'"
background dashboard "(echo 'select 1;'; sleep 600) | $psql"
background billing "$psql -c \"set statement_timeout = '10min'\" -c 'update outils.md5_exercise set prix = prix * 1.02 where stageid = (select stageid from outils.md5_exercise where sessionid = 40)'"
sleep 1
background nightly-batch "$psql -c \"set statement_timeout = '10min'\" -c 'alter table outils.md5_exercise add column checked boolean'"
sleep 1
background reporting "$psql -c \"set statement_timeout = '10min'\" -c 'select count(*) from outils.md5_exercise'"
sleep 1
echo "Six sessions started at $(date -u +%H:%M:%S) UTC, in the database $db. Find the one that blocks the others."
