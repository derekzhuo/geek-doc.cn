#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$ROOT/scripts/common.sh"

printf '=== TEST 1: gdb breakpoint ===\n'
bash "$ROOT/scripts/debug.sh"

printf '\n=== TEST 2: Ubuntu serial boot ===\n'
trap 'stop_vm; release_lock' EXIT
start_vm test
ready=0
for n in $(seq 1 180); do
  if grep -a -q 'riscv-virt login:' "$VM_SERIAL" 2>/dev/null; then
    ready=1
    break
  fi
  kill -0 "$VM_PID" 2>/dev/null || break
  sleep 2
done
[ "$ready" -eq 1 ] || { tail -n 60 "$VM_SERIAL" >&2; fail "login prompt did not appear"; }
grep -a 'riscv-virt login:' "$VM_SERIAL" | tail -n 1
printf 'RESULT: PASS (Ubuntu login prompt)\n'
printf 'RESULT: PASS (all starter-kit checks)\n'
