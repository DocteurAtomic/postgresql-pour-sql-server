#!/usr/bin/env bash
# Module D1 exercise, starting point: an instance limited to 4 GB of memory, in its own
# container pgd1-exercise with the volume pgd1-exercise-data (DOCKER=podman for Podman).
# Runs on the host; the lab is not touched. 2-solution.sh removes both at the end.
set -euo pipefail
docker=${DOCKER:-docker}
name=pgd1-exercise
$docker run -d --name $name --memory 4g --shm-size 256m -e POSTGRES_PASSWORD=course \
    -v $name-data:/var/lib/postgresql \
    docker.io/pgvector/pgvector:pg18 >/dev/null
until $docker exec $name pg_isready -U postgres -h 127.0.0.1 -q 2>/dev/null; do sleep 1; done
echo "Instance ready. Connect with: $docker exec -it $name psql -U postgres"
