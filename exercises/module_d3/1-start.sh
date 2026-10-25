#!/usr/bin/env bash
# Module D3 exercise, starting point. Runs on the host (DOCKER=podman for Podman); the lab is
# not touched. Starts pgd3-exercise, an instance that archives its WAL to the volume
# pgd3-exercise-archive, restores pachadataformation in it, takes a base backup to the
# volume pgd3-exercise-backup, then runs a day of work with a mistake in it. It takes about
# two minutes, since the mistake waits for the next minute. 2-solution.sh removes it all.
set -euo pipefail
cd "$(dirname "$0")"
. ../../demos/module_d3/lib.sh
src=pgd3-exercise
archive_command='test ! -f /archive/wal/%f && cp %p /archive/wal/%f'

$docker volume create pgd3-exercise-archive >/dev/null
$docker run --rm -v pgd3-exercise-archive:/archive --entrypoint bash $image -c 'mkdir -p /archive/wal && chown postgres /archive/wal'
$docker run -d --name $src -e POSTGRES_PASSWORD=course -v pgd3-exercise-archive:/archive \
    -v pgd3-exercise-backup:/backup $image postgres -c archive_mode=on -c "archive_command=$archive_command" >/dev/null
wait_ready $src
$docker exec $src chown postgres /backup
restore_db $src
$docker exec --user postgres $src pg_basebackup -U postgres -D /backup/nightly -Fp -X stream -c fast -l "nightly backup"

q() { sql $src -d pachadataformation -At -q -c "$1"; }
q "update inscription.facture set relance = relance + 1 where datefacture >= '2020-01-01' and relance < 3"
first=$(q "select to_char(now(), 'HH24:MI:SS')")
# the mistake happens 20 seconds into the next minute
sleep $(( 80 - $(date +%s) % 60 ))
q "update stage.session set prix = 0"                     # no where clause
mistake=$(q "select to_char(now(), 'HH24:MI:SS')")
sleep 5
q "update inscription.facture set daterelance = current_date where relance >= 3"
last=$(q "select to_char(now(), 'HH24:MI:SS')")
q "select pg_switch_wal()" >/dev/null
sleep 3
{
    echo "base backup:      /backup/nightly ($(q "select to_char(now(), 'YYYY-MM-DD')"), before the work below)"
    echo "$first  reminders: relance + 1 on the invoices since 2020 (relance < 3)"
    echo "$mistake  the mistake: update stage.session set prix = 0"
    echo "$last  more reminders: daterelance set on the invoices with relance >= 3"
} | $docker exec -i --user postgres $src sh -c 'cat > /backup/day.txt'
$docker exec $src cat /backup/day.txt
echo "Times are UTC, the time zone of the instance. Connect with: $docker exec -it $src psql -U postgres -d pachadataformation"
