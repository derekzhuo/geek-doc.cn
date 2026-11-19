#!/usr/bin/env bash
# Reproduce KLayout DRC deck failures plus the healthy reference run.
# stdout and stderr are merged so ERROR lines keep their real order.
set -u
exec 2>&1

KL="${KLAYOUT_BIN:-klayout}"
printf 'TOOL_VERSION: '
"$KL" -v 2>&1 | head -1

rm -f demo.gds ./*.lyrdb

echo
echo '===== 1. build the input GDS2 ====='
"$KL" -b -r make_gds.rb
printf 'CASE_EXIT make_gds=%s\n' "$?"

for deck in drc_bad_syntax drc_bad_method drc_empty_layer drc_good; do
  echo
  echo "===== $deck ====="
  "$KL" -b -r "${deck}.drc" demo.gds
  printf 'CASE_EXIT %s=%s\n' "$deck" "$?"
done

echo
echo '===== report databases on disk ====='
ls -l ./*.lyrdb
