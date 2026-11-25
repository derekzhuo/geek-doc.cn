#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
mkdir -p results

ngspice --version
printf '\n$ ngspice rc_first.cir\n'
ngspice rc_first.cir
main_rc=$?
printf 'MAIN_EXIT=%s\n' "$main_rc"

printf '\n$ ngspice -b rc_first.cir\n'
ngspice -b rc_first.cir
batch_rc=$?
printf 'BATCH_EXIT=%s\n' "$batch_rc"

printf '\n$ ngspice -b first_line_trap.cir\n'
ngspice -b first_line_trap.cir
trap_rc=$?
printf 'BOUNDARY_EXIT=%s\n' "$trap_rc"

printf '\n$ awk "validate export and print checkpoints" results/tran.data\n'
awk '
NR == 1 && $0 != "time v(in) v(out)" { exit 1 }
NR > 1 && NF == 3 { count++ }
NR == 1 || NR == 2 || NR == 52 || NR == 102 || NR == 152 || NR == 202 { print }
END {
  if (count != 201) exit 1
  print "EXPORT_CHECK: 201 samples"
}' results/tran.data
inspect_rc=$?
printf 'INSPECT_EXIT=%s\n' "$inspect_rc"

if [ "$main_rc" -ne 0 ] || [ "$batch_rc" -ne 0 ] || [ "$trap_rc" -ne 0 ] || [ "$inspect_rc" -ne 0 ]; then
  exit 1
fi
