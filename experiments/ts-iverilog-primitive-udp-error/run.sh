#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '# command: bash run.sh\n'
printf '# date: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
version="$(iverilog -V 2>&1)"
version="${version%%$'\n'*}"
printf '# host-toolchain: %s %s / %s\n' "$(uname -s)" "$(uname -m)" "$version"

printf '$ iverilog -g2012 -tnull udp_bad.v\n'
iverilog -g2012 -tnull udp_bad.v 2>&1
bad_rc=$?
printf '# exit_code: %s (udp_bad.v compile)\n' "$bad_rc"

mkdir -p .build
trap 'rm -rf .build' EXIT
printf '$ iverilog -g2012 -s tb -o .build/and2.vvp udp_fixed.v and2_always.v tb_and2.v\n'
iverilog -g2012 -s tb -o .build/and2.vvp \
  udp_fixed.v and2_always.v tb_and2.v 2>&1
compile_rc=$?
printf '# exit_code: %s (fixed and always compile)\n' "$compile_rc"

sim_rc=1
if [[ "$compile_rc" -eq 0 ]]; then
  printf '$ vvp .build/and2.vvp\n'
  vvp .build/and2.vvp 2>&1
  sim_rc=$?
  printf '# exit_code: %s (four-vector simulation)\n' "$sim_rc"
fi

if [[ "$bad_rc" -eq 1 && "$compile_rc" -eq 0 && "$sim_rc" -eq 0 ]]; then
  printf 'PASS: invalid table rejected; fixed UDP and always passed self-check\n'
  exit 0
fi
printf 'FAIL: unexpected compile or simulation status\n'
exit 1
