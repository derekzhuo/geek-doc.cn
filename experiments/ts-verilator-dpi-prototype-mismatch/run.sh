#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

run_step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ verilator %s\n' "$*"
    verilator "$@" 2>&1
    printf 'exit code: %d\n' "$?"
}

run_make() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ make -C obj_dir -f Vdpi_top.mk Vdpi_top\n'
    make -C obj_dir -f Vdpi_top.mk Vdpi_top 2>&1
    printf 'exit code: %d\n' "$?"
}

run_step "1. SV side: two DPI imports share one name with different prototypes" --cc dpi_bad.sv
rm -rf obj_dir
run_step "2. verilate passes with matching SV declaration, C prototype still wrong" --cc --exe dpi_fixed.sv dpi_bad.cpp --top-module dpi_top
run_make "3. C++ build fails on conflicting DPI prototype"
rm -rf obj_dir
run_step "4. fixed: aligned prototypes, full build" --cc --exe dpi_fixed.sv dpi_fixed.cpp --top-module dpi_top
make -C obj_dir -f Vdpi_top.mk Vdpi_top >/dev/null 2>&1
printf '\n--- 5. run simulation ---\n$ ./obj_dir/Vdpi_top\n'
./obj_dir/Vdpi_top
printf 'exit code: %d\n' "$?"
