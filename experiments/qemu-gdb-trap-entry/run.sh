#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/output"
QEMU="${QEMU:-qemu-system-riscv64}"
GDB_PORT="${GDB_PORT:-1241}"
QEMU_PID=
LOG="$OUT/gdb.log"
RUN_LOG="$OUT/run.log"

if [ -z "${GDB:-}" ]; then
  if command -v riscv64-elf-gdb >/dev/null 2>&1; then
    GDB="$(command -v riscv64-elf-gdb)"
  else
    GDB="$(command -v gdb-multiarch)"
  fi
fi
for tool in "$QEMU" "$GDB"; do
  command -v "$tool" >/dev/null 2>&1 || { echo "FATAL: missing $tool" >&2; exit 1; }
done

cleanup() {
  if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
    kill "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
mkdir -p "$OUT"
rm -f "$LOG" "$RUN_LOG"
exec > >(tee "$RUN_LOG") 2>&1

"$QEMU" \
  -machine virt -smp 1 -m 256M -bios default \
  -display none -monitor none -serial none \
  -S -gdb "tcp:127.0.0.1:$GDB_PORT" &
QEMU_PID=$!
sleep 1
kill -0 "$QEMU_PID" 2>/dev/null || { echo "FATAL: QEMU exited before gdb connected" >&2; exit 1; }

"$GDB" -q -nx -batch \
  -ex 'set pagination off' \
  -ex 'set architecture riscv:rv64' \
  -ex "target remote 127.0.0.1:$GDB_PORT" \
  -ex 'printf "RESET_PC=%#lx\n", $pc' \
  -ex 'break *0x80000000' \
  -ex 'continue' \
  -ex 'disable 1' \
  -ex 'printf "PATCH_RAM_WITH_ECALL_MRET_NOP\n"' \
  -ex 'set {unsigned int}0x80000000 = 0x00000073' \
  -ex 'set {unsigned int}0x80000004 = 0x00000013' \
  -ex 'set {unsigned int}0x80200000 = 0x00000013' \
  -ex 'set {unsigned int}0x80200100 = 0x30200073' \
  -ex 'x/3i 0x80000000' \
  -ex 'x/i 0x80200100' \
  -ex 'set $mtvec = 0x80200100' \
  -ex 'stepi' \
  -ex 'printf "TRAP_PC=%#lx\n", $pc' \
  -ex 'printf "TRAP_MCAUSE=%#lx\n", $mcause' \
  -ex 'printf "TRAP_MEPC=%#lx\n", $mepc' \
  -ex 'printf "TRAP_MTVAL=%#lx\n", $mtval' \
  -ex 'printf "TRAP_MTVEC=%#lx\n", $mtvec' \
  -ex 'printf "TRAP_PRIV=%#lx\n", $priv' \
  -ex 'printf "INITIAL_PMP_CFG0=%#lx\n", $pmpcfg0' \
  -ex 'printf "INITIAL_PMP_ADDR0=%#lx\n", $pmpaddr0' \
  -ex 'set $mepc = 0x80200000' \
  -ex 'set $mstatus = ($mstatus & ~0x1800) | 0x0800' \
  -ex 'printf "NO_PMP_ATTEMPT_MEPC=%#lx\n", $mepc' \
  -ex 'printf "NO_PMP_ATTEMPT_MPP=%#lx\n", ($mstatus >> 11) & 3' \
  -ex 'stepi' \
  -ex 'printf "NO_PMP_PC=%#lx\n", $pc' \
  -ex 'printf "NO_PMP_MCAUSE=%#lx\n", $mcause' \
  -ex 'printf "NO_PMP_MEPC=%#lx\n", $mepc' \
  -ex 'printf "NO_PMP_MTVAL=%#lx\n", $mtval' \
  -ex 'printf "NO_PMP_PRIV=%#lx\n", $priv' \
  -ex 'set $pmpaddr0 = -1' \
  -ex 'set $pmpcfg0 = 0x1f' \
  -ex 'set $mepc = 0x80200000' \
  -ex 'set $mstatus = ($mstatus & ~0x1800) | 0x0800' \
  -ex 'printf "PMP_CFG0=%#lx\n", $pmpcfg0' \
  -ex 'printf "PMP_ADDR0=%#lx\n", $pmpaddr0' \
  -ex 'printf "RETURN_ATTEMPT_MEPC=%#lx\n", $mepc' \
  -ex 'printf "RETURN_ATTEMPT_MPP=%#lx\n", ($mstatus >> 11) & 3' \
  -ex 'stepi' \
  -ex 'printf "RETURN_PC=%#lx\n", $pc' \
  -ex 'printf "RETURN_MCAUSE=%#lx\n", $mcause' \
  -ex 'printf "RETURN_MEPC=%#lx\n", $mepc' \
  -ex 'printf "RETURN_MTVAL=%#lx\n", $mtval' \
  -ex 'printf "RETURN_MPP=%#lx\n", ($mstatus >> 11) & 3' \
  -ex 'printf "RETURN_MPIE=%#lx\n", ($mstatus >> 7) & 1' \
  -ex 'printf "RETURN_PRIV=%#lx\n", $priv' \
  -ex 'x/i $pc' \
  -ex 'detach' 2>&1 | tee "$LOG"

grep -Fxq 'RESET_PC=0x1000' "$LOG"
grep -q 'PATCH_RAM_WITH_ECALL_MRET_NOP' "$LOG"
grep -q '=> 0x80000000:[[:space:]]*ecall' "$LOG"
grep -Eq '^[[:space:]]+0x80200100:[[:space:]]*mret' "$LOG"
grep -Fxq 'TRAP_PC=0x80200100' "$LOG"
grep -Fxq 'TRAP_MCAUSE=0xb' "$LOG"
grep -Fxq 'TRAP_MEPC=0x80000000' "$LOG"
grep -Fxq 'TRAP_MTVAL=0' "$LOG"
grep -Fxq 'TRAP_MTVEC=0x80200100' "$LOG"
grep -Fxq 'TRAP_PRIV=0x3' "$LOG"
grep -Fxq 'INITIAL_PMP_CFG0=0' "$LOG"
grep -Fxq 'INITIAL_PMP_ADDR0=0' "$LOG"
grep -Fxq 'NO_PMP_ATTEMPT_MEPC=0x80200000' "$LOG"
grep -Fxq 'NO_PMP_ATTEMPT_MPP=0x1' "$LOG"
grep -Fxq 'NO_PMP_PC=0x80200100' "$LOG"
grep -Fxq 'NO_PMP_MCAUSE=0x1' "$LOG"
grep -Fxq 'NO_PMP_MEPC=0x80200100' "$LOG"
grep -Fxq 'NO_PMP_MTVAL=0' "$LOG"
grep -Fxq 'NO_PMP_PRIV=0x3' "$LOG"
grep -Fxq 'PMP_CFG0=0x1f' "$LOG"
grep -Fxq 'PMP_ADDR0=0x3fffffffffffff' "$LOG"
grep -Fxq 'RETURN_ATTEMPT_MEPC=0x80200000' "$LOG"
grep -Fxq 'RETURN_ATTEMPT_MPP=0x1' "$LOG"
grep -Fxq 'RETURN_PC=0x80200000' "$LOG"
grep -Fxq 'RETURN_MCAUSE=0x1' "$LOG"
grep -Fxq 'RETURN_MEPC=0x80200000' "$LOG"
grep -Fxq 'RETURN_MTVAL=0' "$LOG"
grep -Fxq 'RETURN_MPP=0' "$LOG"
grep -Fxq 'RETURN_MPIE=0x1' "$LOG"
grep -Fxq 'RETURN_PRIV=0x1' "$LOG"
grep -q '=> 0x80200000:[[:space:]]*nop' "$LOG"
printf 'RESULT: PASS (ecall trap, PMP failure contrast, and mret return to S-mode)\n'
