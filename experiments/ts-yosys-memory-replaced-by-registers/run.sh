#!/usr/bin/env bash
set -euo pipefail

run_case() {
    local source="$1"
    printf '\n===== CASE %s =====\n' "$source"
    yosys -Q -T -p "read_verilog $source; hierarchy -top top; proc; opt; memory_dff; stat; memory_collect; stat; memory_map; stat"
}

run_case async_read.v
run_case sync_read.v
printf '\nPASS: both Yosys runs completed; compare the three stat blocks per case.\n'
