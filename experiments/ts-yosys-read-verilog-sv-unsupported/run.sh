#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

{
    printf '# command: bash run.sh\n'
    printf '# date: %s\n' "$(date +%F)"
    printf '# host-toolchain: %s\n' "$(yosys -V)"

    printf '\n$ yosys -V\n'
    yosys -V

    printf "\n\$ yosys -p 'read_verilog -sv package_original.sv'\n"
    set +e
    yosys -p 'read_verilog -sv package_original.sv'
    original_rc=$?
    set -e
    printf 'ORIGINAL_EXIT=%d\n' "$original_rc"
    if [ "$original_rc" -eq 0 ]; then
        printf 'UNEXPECTED: original package source was accepted\n'
        exit 1
    fi

    printf "\n\$ yosys -p 'read_verilog -sv localparam_rewritten.sv; hierarchy -top top; proc; check'\n"
    yosys -p 'read_verilog -sv localparam_rewritten.sv; hierarchy -top top; proc; check'
    rewrite_rc=$?
    printf 'REWRITE_EXIT=%d\n' "$rewrite_rc"
    if [ "$rewrite_rc" -ne 0 ]; then
        exit "$rewrite_rc"
    fi

    printf 'RESULT: original package rejected; localparam rewrite PASS\n'
} > run1.log 2>&1

cat run1.log
