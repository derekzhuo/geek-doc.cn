#!/usr/bin/env bash
set -euo pipefail
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
docker run --rm -v "$ROOT":/work -w /work geek-eda:0.4-flow bash scripts/run-container.sh
