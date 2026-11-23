#!/usr/bin/env bash
# macOS/Linux entry point: run all five labs.
set -euo pipefail
cd "$(dirname "$0")"
make test
