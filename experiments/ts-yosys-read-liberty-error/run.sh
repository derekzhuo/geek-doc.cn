#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '$ bash run.sh\n'
printf 'image=geek-eda:0.2\n'
docker run --rm geek-eda:0.2 yosys -V

printf '\n=== bad.lib: read_liberty ===\n'
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 \
  yosys -p 'read_liberty bad.lib' 2>&1
bad_rc=$?
printf 'bad_exit=%s\n' "$bad_rc"

printf '\n=== good.lib: read_liberty and abc -liberty ===\n'
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 \
  yosys -p 'read_liberty -lib good.lib; read_verilog top.v; hierarchy -top top; proc; opt; techmap; opt; abc -liberty good.lib; stat; write_verilog /tmp/ts-yosys-read-liberty-error-mapped.v' 2>&1
good_rc=$?
printf 'good_exit=%s\n' "$good_rc"

test "$bad_rc" -ne 0 || exit 1
test "$good_rc" -eq 0 || exit 1
printf 'PASS bad input rejected; good library loaded and mapped\n'
