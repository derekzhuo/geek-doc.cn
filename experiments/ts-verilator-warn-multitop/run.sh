#!/usr/bin/env bash
set -u

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

printf '%s\n' '# command: docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run'
printf '# date: %s\n' "$(date +%F)"
printf '# host-toolchain: %s\n' "$(verilator --version)"

printf '\n== broken: two unrelated roots ==\n'
set +e
verilator --lint-only multitop.sv >"$workdir/broken.log" 2>&1
broken_status=$?
set -e
cat "$workdir/broken.log"
printf 'broken exit=%s\n' "$broken_status"

printf '\n== fixed: select chip_top ==\n'
set +e
verilator --lint-only --top-module chip_top multitop.sv >"$workdir/fixed.log" 2>&1
fixed_status=$?
set -e
cat "$workdir/fixed.log"
if [[ ! -s "$workdir/fixed.log" ]]; then
    printf 'fixed diagnostics: none\n'
fi
printf 'fixed exit=%s\n' "$fixed_status"

printf '\n== hierarchy after chip_top selection ==\n'
verilator --xml-only --xml-output "$workdir/chip_top.xml" --top-module chip_top multitop.sv
module_count="$(grep -c '<module ' "$workdir/chip_top.xml")"
printf 'xml modules after chip_top pruning=%s\n' "$module_count"
if grep -q "name='debug_top'" "$workdir/chip_top.xml"; then
    printf 'xml contains debug_top=yes\n'
    debug_present=1
else
    printf 'xml contains debug_top=no\n'
    debug_present=0
fi

if [[ "$broken_status" -eq 1 ]] \
    && grep -q '%Warning-MULTITOP' "$workdir/broken.log" \
    && [[ "$fixed_status" -eq 0 ]] \
    && [[ "$module_count" -eq 1 ]] \
    && [[ "$debug_present" -eq 0 ]]; then
    printf 'PASS: MULTITOP reproduced; --top-module fixes lint and prunes hierarchy\n'
else
    printf 'FAIL: expected MULTITOP, successful fixed lint, and one-module hierarchy\n'
    exit 1
fi
