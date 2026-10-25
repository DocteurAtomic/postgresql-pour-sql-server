#!/usr/bin/env bash
# Clip 2.1: the same processes, seen from the operating system of the container.
# Runs on the host, against the lab container pgcourse (DOCKER=podman for Podman).
# It opens a psql session in the background for ten seconds, to show its process.
set -euo pipefail
docker=${DOCKER:-docker}
db=${DB:-pachadataformation}
$docker exec pgcourse psql -U postgres -d "$db" -X -q \
    -c "select pg_sleep(10)" >/dev/null &
sleep 2
# PID 1 is the postmaster; every other postgres process is its child (PPID 1).
$docker top pgcourse pid ppid args
wait
