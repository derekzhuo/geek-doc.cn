#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

run_step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ verilator %s\n' "$*"
    verilator "$@" 2>&1
    printf 'exit code: %d\n' "$?"
}

run_step "1. verilate stage accepts the design and testbench" --cc --exe simple.v tb_bad.cpp --top-module simple
printf '\n--- 2. make stage: g++ cannot find the missing header ---\n'
printf '$ make -C obj_dir -f Vsimple.mk Vsimple\n'
make -C obj_dir -f Vsimple.mk Vsimple 2>&1
printf 'exit code: %d\n' "$?"
rm -rf obj_dir
run_step "3. fixed testbench: verilate and make both pass" --cc --exe simple.v tb_fixed.cpp --top-module simple
make -C obj_dir -f Vsimple.mk Vsimple >/dev/null 2>&1
printf 'make exit code: %d\n' "$?"
printf '\n--- 4. run simulation ---\n$ ./obj_dir/Vsimple\n'
./obj_dir/Vsimple
printf 'exit code: %d\n' "$?"
