#!/usr/bin/env bash
set -u

cd "$(dirname "$0")"
mkdir -p build

iv_version="$(iverilog -V 2>&1)"
iv_version="${iv_version%%$'\n'*}"

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s %s / %s\n' "$(uname -s)" "$(uname -m)" "$iv_version"

printf '\n$ iverilog -g2012 -s tb_bad -o build/tb_bad.vvp counter.v tb_bad.v\n'
iverilog -g2012 -s tb_bad -o build/tb_bad.vvp counter.v tb_bad.v 2>&1
bad_rc=$?
printf '[exit] %s\n' "$bad_rc"
if [ "$bad_rc" -eq 0 ]; then
  printf 'FAIL: bad case unexpectedly compiled\n'
  exit 1
fi

printf '\n$ iverilog -g2012 -s tb_good -o build/tb_good.vvp counter.v tb_good.v\n'
iverilog -g2012 -s tb_good -o build/tb_good.vvp counter.v tb_good.v 2>&1
good_compile_rc=$?
printf '[exit] %s\n' "$good_compile_rc"
if [ "$good_compile_rc" -ne 0 ]; then
  exit "$good_compile_rc"
fi

printf '\n$ vvp build/tb_good.vvp\n'
vvp build/tb_good.vvp 2>&1
good_run_rc=$?
printf '[exit] %s\n' "$good_run_rc"
exit "$good_run_rc"
