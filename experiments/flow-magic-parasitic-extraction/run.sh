#!/usr/bin/env bash
set -euo pipefail

image=geek-eda:0.5-asic
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
printf '%s\n' '$ docker run --rm -i -v <experiment>:/work -w /work geek-eda:0.5-asic bash run-container.sh'
docker run --rm -i -v "${script_dir}:/work" -w /work "$image" bash run-container.sh
