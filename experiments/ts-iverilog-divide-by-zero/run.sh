#!/usr/bin/env bash
set -u

cd "$(dirname "$0")"
LOG="${1:-run1.log}"
VERSION_OUTPUT="$(iverilog -V 2>&1)"
VERSION_LINE="${VERSION_OUTPUT%%$'\n'*}"

{
    printf '# command: bash run.sh\n'
    printf '# date: %s\n' "$(date +%F)"
    printf '# host-toolchain: %s / %s\n' "$(uname -srm)" "$VERSION_LINE"

    overall=0

    printf '$ iverilog -g2012 -s tb -o bad_simv bad.sv\n'
    iverilog -g2012 -s tb -o bad_simv bad.sv
    rc=$?
    printf 'bad compile exit=%d\n' "$rc"
    if [ "$rc" -ne 0 ]; then overall=1; fi

    printf '$ vvp bad_simv\n'
    vvp bad_simv
    rc=$?
    printf 'bad run exit=%d\n' "$rc"
    if [ "$rc" -ne 0 ]; then overall=1; fi

    printf '$ iverilog -g2012 -s tb -o fixed_simv fixed.sv\n'
    iverilog -g2012 -s tb -o fixed_simv fixed.sv
    rc=$?
    printf 'fixed compile exit=%d\n' "$rc"
    if [ "$rc" -ne 0 ]; then overall=1; fi

    printf '$ vvp fixed_simv\n'
    vvp fixed_simv
    rc=$?
    printf 'fixed run exit=%d\n' "$rc"
    if [ "$rc" -ne 0 ]; then overall=1; fi

    if [ "$overall" -eq 0 ]; then
        printf 'PASS: x behavior observed and guarded division verified\n'
    else
        printf 'FAIL: compile or simulation returned nonzero\n'
    fi
} >"$LOG" 2>&1
rc=$?

cat "$LOG"
exit "$rc"
