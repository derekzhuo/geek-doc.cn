#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$ROOT/scripts/common.sh"

acquire_lock
trap release_lock EXIT
find "$OUT" -mindepth 1 -maxdepth 1 ! -name .lock -exec rm -rf {} +
printf 'Removed generated files from %s\n' "$OUT"
if [ "${1:-}" = "distclean" ]; then
  rm -rf "$ASSETS"
  printf 'Removed downloaded assets from %s\n' "$ASSETS"
fi
