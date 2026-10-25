#!/usr/bin/env bash
# ci: skip (two concurrent applications, on the host, against the lab container pgcourse)
# Clip V3.3: two applications enroll a trainee in session 41 at the same time, in
# serializable, each with a retry loop on SQLSTATE 40001 and 40P01. The loop replays the
# whole transaction (03-enroll.sql), reads and decision included. With WRONG=1, it replays
# only the INSERT (03-insert-only.sql), with the decision of the failed attempt.
#   DOCKER=podman ./demos/module_v3/03-retry.sh
#   DOCKER=podman WRONG=1 ./demos/module_v3/03-retry.sh
set -uo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
dir=$(dirname "$0")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
psql_run() { $docker exec -i pgcourse sh -c "psql -U postgres -d '$db' -X -q $* 2>&1"; }

psql_run <<< "delete from outils.mv3_inscription where inscriptionid >= 900000;" > /dev/null

# app NAME ID PAUSE: one application, at most five attempts.
app() {
    local name=$1 id=$2 pause=$3 attempt=1 script=03-enroll.sql out
    while [ $attempt -le 5 ]; do
        out=$(psql_run -v app="$name" -v id="$id" -v pause="$pause" < "$dir/$script")
        echo "$out" | grep -v "^LOCATION:" | sed "s/^/[$name, attempt $attempt] /"
        if ! echo "$out" | grep -q '^ERROR'; then
            return 0                                   # committed
        fi
        if ! echo "$out" | grep -Eq '^ERROR:  (40001|40P01)'; then
            echo "[$name] not retryable, giving up"; return 1
        fi
        [ "${WRONG:-0}" = 1 ] && script=03-insert-only.sql
        sleep "0.$((RANDOM % 5 + 1))"                  # back off, with jitter
        pause=0
        attempt=$((attempt + 1))
    done
    echo "[$name] five attempts failed"; return 1
}

app A 900001 2 > "$tmp/a.txt" &
sleep 1
app B 900002 2 > "$tmp/b.txt" &
wait
cat "$tmp/a.txt" "$tmp/b.txt"
psql_run <<< "select count(*) as enrolled from outils.mv3_inscription where sessionid = 41;
delete from outils.mv3_inscription where inscriptionid >= 900000;"
