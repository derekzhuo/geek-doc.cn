#!/usr/bin/env bash
# Run all STA summary cases. OpenSTA 2.0.17 always exits 0 even after a Tcl
# `exit N`, so the wrapper maps the printed STA_STATUS line to an exit code:
#   MET=0  VIOLATED=1  NO_CLOCKS/SCRIPT_ERROR=2
set -u
STA_BIN="${STA_BIN:-sta}"

run_case() {
  local name="$1"; shift
  printf '\n===== %s =====\n' "$name"
  local out
  out="$("$STA_BIN" -no_init -exit "${name}.tcl" 2>&1)"
  printf '%s\n' "$out"
  local status
  status="$(printf '%s\n' "$out" | sed -n 's/^STA_STATUS .*status=\([A-Z_]*\).*/\1/p' | tail -1)"
  case "$status" in
    MET)        local code=0 ;;
    VIOLATED)   local code=1 ;;
    NO_CLOCKS|SCRIPT_ERROR|"") local code=2 ;;
    *)          local code=2 ;;
  esac
  printf 'CASE_EXIT %s=%s (status=%s)\n' "$name" "$code" "$status"
}

run_case case_met
run_case case_violated_setup
run_case case_violated_hold
run_case case_noclock
run_case case_margin
run_case case_csv
