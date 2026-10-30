#!/bin/sh
set -u

cd "$(dirname "$0")"
printf '# command: sh run.sh\n'
printf '# date: %s\n' "$(date -Iseconds)"
printf '# host-toolchain: %s / %s\n' "$(uname -srm)" "$(iverilog -V 2>/dev/null | head -n 1)"

printf '%s\n' '--- compile bad.v (wire driven from always) ---'
iverilog -g2012 -s bad -o bad.vvp bad.v 2>&1
bad_status=$?
printf '# exit_code: %s\n' "$bad_status"

printf '%s\n' '--- compile and run fixed.v (reg driven from always) ---'
iverilog -g2012 -s tb -o fixed_tb.vvp fixed.v tb.v 2>&1
compile_status=$?
printf '# compile_exit_code: %s\n' "$compile_status"
if [ "$compile_status" -eq 0 ]; then
    vvp fixed_tb.vvp 2>&1
    run_status=$?
else
    run_status=1
fi
printf '# run_exit_code: %s\n' "$run_status"

rm -f bad.vvp fixed_tb.vvp
if [ "$bad_status" -ne 0 ] && [ "$compile_status" -eq 0 ] && [ "$run_status" -eq 0 ]; then
    exit 0
fi
exit 1
