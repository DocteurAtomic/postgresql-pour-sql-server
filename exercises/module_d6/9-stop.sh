#!/usr/bin/env bash
# Exercise D6, stop: removes the containers, volumes and network of the exercise.
set -euo pipefail
. "$(dirname "$0")/../../demos/module_d6/lib.sh"
cleanup pgd6-exercise-primary pgd6-exercise-standby
echo "Removed the containers, volumes and network of exercise D6."
