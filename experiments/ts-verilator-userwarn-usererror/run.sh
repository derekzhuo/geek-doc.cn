#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

run_lint() {
    local label="$1"
    shift
    printf '\n--- %s ---\n' "$label"
    printf '$ verilator %s\n' "$*"
    verilator "$@"
    local rc=$?
    printf 'exit code: %d\n' "$rc"
    return 0
}

run_lint "USERWARN: non-power-of-two DEPTH" --lint-only -Wall userwarn_bad.sv
run_lint "USERERROR: non-positive WIDTH" --lint-only -Wall usererror_bad.sv
run_lint "USERWARN with warnings made non-fatal" --lint-only -Wall -Wno-fatal userwarn_bad.sv
run_lint "USERERROR with warnings made non-fatal" --lint-only -Wall -Wno-fatal usererror_bad.sv
run_lint "fixed: legal parameter values" --lint-only -Wall params_fixed.sv
run_lint "fixed guards still reject WIDTH=0" --lint-only -Wall -GWIDTH=0 params_fixed.sv
