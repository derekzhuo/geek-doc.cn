#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

printf '%s\n' '=== bad: two clock edges in one always ==='
printf '%s\n' "# run: yosys -p 'read_verilog multi_clock_bad.v; hierarchy -top multi_clock_bad; proc; check'"
yosys -p 'read_verilog multi_clock_bad.v; hierarchy -top multi_clock_bad; proc; check' 2>&1
bad_rc=$?
printf '# bad-exit-code: %s\n\n' "$bad_rc"

printf '%s\n' '=== fixed: one clock per always ==='
printf '%s\n' "# run: yosys -p 'read_verilog multi_clock_fixed.v; hierarchy -top multi_clock_fixed; proc; check'"
yosys -p 'read_verilog multi_clock_fixed.v; hierarchy -top multi_clock_fixed; proc; check' 2>&1
fixed_rc=$?
printf '# fixed-exit-code: %s\n' "$fixed_rc"

if [ "$bad_rc" -eq 1 ] && [ "$fixed_rc" -eq 0 ]; then
    printf '%s\n' 'RESULT: PASS (bad rejected with exit 1; fixed passed with exit 0)'
    exit 0
fi

printf 'RESULT: FAIL (bad=%s, fixed=%s; expected 1 and 0)\n' "$bad_rc" "$fixed_rc"
exit 1
