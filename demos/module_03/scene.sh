#!/usr/bin/env bash
# Plays a scene of the module with two sessions or more, in one command, on the host,
# against the lab container pgcourse (DOCKER=podman for Podman, DB=<database> otherwise).
#   ./demos/module_03/scene.sh demos/module_03/02a-writer.sql demos/module_03/02b-reader.sql
# Each script starts one second after the previous one (DELAY=<seconds> to change it) and
# times itself with pg_sleep. The outputs are printed once all have finished, in the order
# of the scripts; psql echoes each statement (-e) and its errors in place.
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
delay=${DELAY:-1}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
play() { $docker exec -i pgcourse sh -c "psql -U postgres -d '$db' -X -e 2>&1"; }
n=0
for f in "$@"; do
    [ $n -gt 0 ] && sleep "$delay"
    play < "$f" > "$tmp/$n.txt" &
    n=$((n + 1))
done
wait
n=0
for f in "$@"; do
    echo "=== session $(printf "\\x$(printf %x $((65 + n)))"): $(basename "$f")"
    cat "$tmp/$n.txt"
    n=$((n + 1))
done
