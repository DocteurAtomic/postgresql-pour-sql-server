#!/usr/bin/env bash
# Runs every demo and exercise script of the lab in order, stopping at the first error.
# A script whose first lines contain "-- ci: skip" (two sessions, instance changes) is skipped.
# Usage: ./setup/run-scripts.sh [module folder name ...]
set -euo pipefail
cd "$(dirname "$0")/.."
compose=${COMPOSE:-docker compose}
modules=("$@")
[ ${#modules[@]} -eq 0 ] && modules=($(ls demos exercises 2>/dev/null | grep '^module_' | sort -u))
for m in "${modules[@]}"; do
    for f in $(ls demos/$m/*.sql exercises/$m/*.sql 2>/dev/null | sort); do
        if head -5 "$f" | grep -q -- '-- ci: skip'; then echo "skip $f"; continue; fi
        echo "run  $f"
        $compose exec -T db psql -U postgres -d pachadataformation -X -q -v ON_ERROR_STOP=1 -f "/$f" >/dev/null
    done
done
