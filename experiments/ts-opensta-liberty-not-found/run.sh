#!/usr/bin/env bash
# Reproduce all read_liberty failure modes plus the valid reference run.
# stdout and stderr are merged on purpose so the log keeps the exact order
# of OpenSTA "Error:" diagnostics and Tcl puts lines.
set -u
exec 2>&1

STA_BIN="${STA_BIN:-sta}"
printf 'TOOL_VERSION: '
"$STA_BIN" -version | head -1

# Case 3 feeds a gzip-compressed liberty directly to read_liberty.
gzip -c minimal.lib > mini.lib.gz

for case_name in missing broken valid; do
  printf '\n===== %s =====\n' "$case_name"
  "$STA_BIN" -no_init -exit "${case_name}.tcl"
  printf 'CASE_EXIT %s=%s\n' "$case_name" "$?"
done

rm -f mini.lib.gz
