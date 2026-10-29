#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

run_compile() {
    local name="$1"
    local source="$2"
    printf '\n=== %s ===\n' "$name"
    printf '$ iverilog -g2005 -s %s -o %s.vvp %s\n' "$name" "$name" "$source"
    iverilog -g2005 -s "$name" -o "$name.vvp" "$source" 2>&1
    local rc=$?
    printf '%s exit=%d\n' "$name" "$rc"
    return "$rc"
}

run_compile broken_integer broken_integer.v
integer_rc=$?
run_compile broken_no_generate broken_no_generate.v
generate_rc=$?
run_compile fixed_generate fixed_generate.v
fixed_rc=$?

sim_rc=1
if [ "$fixed_rc" -eq 0 ]; then
    printf '\n=== fixed simulation ===\n'
    printf '$ iverilog -g2005 -s tb_fixed_generate -o tb_fixed_generate.vvp fixed_generate.v tb_fixed_generate.v\n'
    iverilog -g2005 -s tb_fixed_generate -o tb_fixed_generate.vvp fixed_generate.v tb_fixed_generate.v 2>&1
    compile_tb_rc=$?
    printf 'fixed-testbench-compile exit=%d\n' "$compile_tb_rc"
    if [ "$compile_tb_rc" -eq 0 ]; then
        printf '$ vvp tb_fixed_generate.vvp\n'
        vvp tb_fixed_generate.vvp 2>&1
        sim_rc=$?
        printf 'fixed-simulation exit=%d\n' "$sim_rc"
    else
        sim_rc=$compile_tb_rc
    fi
fi

if [ "$integer_rc" -ne 0 ] && [ "$generate_rc" -eq 0 ] && [ "$fixed_rc" -eq 0 ] && [ "$sim_rc" -eq 0 ]; then
    printf '\nPASS: integer genvar error reproduced; omitted generate accepted; fixed compile and simulation exited 0\n'
    exit 0
fi
printf '\nFAIL: unexpected result integer=%d no-generate=%d fixed=%d simulation=%d\n' "$integer_rc" "$generate_rc" "$fixed_rc" "$sim_rc"
exit 1
