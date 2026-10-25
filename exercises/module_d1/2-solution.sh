#!/usr/bin/env bash
# Module D1 exercise, solution: the whole run, from the memory the container sees to the
# reset. Runs on the host, after 1-start.sh (DOCKER=podman for Podman). Removes the
# container pgd1-exercise and its volume at the end, unless KEEP=1.
set -euo pipefail
cd "$(dirname "$0")"
docker=${DOCKER:-docker}
name=pgd1-exercise
cleanup() { [ "${KEEP:-0}" = 1 ] || { $docker rm -f $name >/dev/null 2>&1; $docker volume rm -f $name-data >/dev/null 2>&1; }; }
trap cleanup EXIT
wait_ready() { until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done; }
run() { $docker exec -i $name sh -c 'psql -U postgres -X 2>&1' < "$1"; }

echo "== 1. the memory the instance can count on"
$docker exec $name sh -c 'awk "/MemTotal/ {printf \"MemTotal: %.1f GB\n\", \$2/1048576}" /proc/meminfo
    awk "{printf \"memory.max: %.1f GB\n\", \$1/1073741824}" /sys/fs/cgroup/memory.max'
echo "== 2 and 3. ALTER SYSTEM, reload"
run 2-solution.sql
echo "== 4. restart"
$docker restart $name >/dev/null; wait_ready
run 2-after-restart.sql
echo "== 5. undo"
run 3-reset.sql
