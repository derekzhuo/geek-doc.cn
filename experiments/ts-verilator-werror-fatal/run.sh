#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"

run_step() {
    printf '\n--- %s ---\n' "$1"; shift
    printf '$ verilator %s\n' "$*"
    verilator "$@" 2>&1
    printf 'exit code: %d\n' "$?"
}

run_step "0. bare double-dash --Werror is not a valid option in 5.020" --lint-only --Werror latch_bad.v
run_step "1. bare single-dash -Werror needs a message suffix" --lint-only -Werror latch_bad.v
run_step "2. advisory mode: -Wno-fatal downgrades LATCH to warning" --lint-only -Wno-fatal latch_bad.v
run_step "3. default run: LATCH is fatal out of the box" --lint-only latch_bad.v
run_step "4. explicit escalation: -Werror-LATCH overrides -Wno-fatal" --lint-only -Wno-fatal -Werror-LATCH latch_bad.v
run_step "5. graded waiver: -Wno-LATCH silences this message" --lint-only -Wno-LATCH latch_bad.v
run_step "6. fixed RTL: complete the if/else so no latch is inferred" --lint-only latch_fixed.v
