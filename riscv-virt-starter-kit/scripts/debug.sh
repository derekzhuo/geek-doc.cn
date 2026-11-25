#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$ROOT/scripts/common.sh"

need_cmd "$QEMU"
need_cmd "$GDB"
acquire_lock
trap 'stop_vm; release_lock' EXIT
LOG="$OUT/debug.log"

"$QEMU" -machine virt -bios default \
  -display none -serial none -monitor none \
  -gdb "tcp:127.0.0.1:$GDB_PORT" -S -no-reboot \
  >"$OUT/debug-qemu.log" 2>&1 &
VM_PID=$!
sleep 1
kill -0 "$VM_PID" 2>/dev/null || fail "QEMU could not open gdb port $GDB_PORT"

printf 'PC at reset, breakpoint at OpenSBI entry, then two single steps:\n'
run_with_timeout 45 "$GDB" -q -nx -batch \
  -ex 'set architecture riscv:rv64' \
  -ex "target remote 127.0.0.1:$GDB_PORT" \
  -ex 'info registers pc' \
  -ex 'break *0x80000000' \
  -ex 'continue' \
  -ex 'info registers pc' \
  -ex 'x/4i $pc' \
  -ex 'stepi' \
  -ex 'stepi' \
  -ex 'info registers pc' 2>&1 | tee "$LOG"

grep -q 'Breakpoint 1,' "$LOG" || fail "OpenSBI breakpoint was not hit"
grep -Eq 'pc[[:space:]]+0x80000000([[:space:]]|$)' "$LOG" || fail "PC did not stop at OpenSBI entry"
grep -Eq 'pc[[:space:]]+0x80000008([[:space:]]|$)' "$LOG" || fail "PC did not advance by two instructions"
printf 'RESULT: PASS (gdb breakpoint and single-step)\n'
