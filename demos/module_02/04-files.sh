#!/usr/bin/env bash
# Clip 2.4: the files of the data directory, seen from the container of the lab.
# Runs on the host, against the lab container pgcourse (DOCKER=podman for Podman).
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
q() { $docker exec pgcourse psql -U postgres -d "$db" -XAt -c "$1"; }
pgdata=$(q "show data_directory")
$docker exec pgcourse ls "$pgdata"
echo
file=$(q "select pg_relation_filepath('stage.session')")
echo "stage.session: $file"
$docker exec pgcourse sh -c "ls -l $pgdata/$file*"
# Every file of the database: catalogs, tables, indexes and their forks.
dir=$(dirname "$file")
echo "files in $dir: $($docker exec pgcourse sh -c "ls $pgdata/$dir | wc -l")"
echo
# The WAL segments, 16 MB each.
$docker exec pgcourse sh -c "ls -l $pgdata/pg_wal | head -4"
