#!/usr/bin/env bash
# Clip D1.3: the memory a container limited to 4 GB sees, and its /dev/shm.
# Runs on the host, in a throwaway container pgd1-limit (DOCKER=podman for Podman),
# removed at the end. The lab is not touched.
set -euo pipefail
docker=${DOCKER:-docker}
image=docker.io/pgvector/pgvector:pg18
for opts in "--memory 4g" "--memory 4g --shm-size 256m"; do
    echo "== $docker run $opts"
    $docker run --rm --name pgd1-limit $opts --entrypoint sh $image -c '
        echo "MemTotal of /proc/meminfo: $(awk "/MemTotal/ {printf \"%.1f GB\", \$2/1048576}" /proc/meminfo)"
        echo "cgroup memory.max:         $(awk "{printf \"%.1f GB\", \$1/1073741824}" /sys/fs/cgroup/memory.max)"
        df -h /dev/shm | awk "NR == 2 {print \"/dev/shm:                  \" \$2}"'
done
