#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$ROOT/assets"
OUT="$ROOT/output"
DEB="$ASSETS/u-boot-qemu_2024.01+dfsg-1ubuntu5_all.deb"
UBOOT="$ASSETS/u-boot-riscv64.bin"
URL="https://ports.ubuntu.com/pool/main/u/u-boot/u-boot-qemu_2024.01+dfsg-1ubuntu5_all.deb"
SHA256="2bf5e506844d34dc574dbce23f5a4768c72f8e085d2da1b89a94445d257a51a0"
QEMU="${QEMU:-qemu-system-riscv64}"
GDB_PORT="${GDB_PORT:-1240}"
QEMU_PID=
LOG="$OUT/gdb.log"

if [ -z "${GDB:-}" ]; then
  if command -v riscv64-elf-gdb >/dev/null 2>&1; then
    GDB="$(command -v riscv64-elf-gdb)"
  else
    GDB="$(command -v gdb-multiarch)"
  fi
fi

for tool in "$QEMU" "$GDB" curl ar tar; do
  command -v "$tool" >/dev/null 2>&1 || { echo "FATAL: missing $tool" >&2; exit 1; }
done

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  else
    sha256sum "$1" | cut -d ' ' -f 1
  fi
}

cleanup() {
  if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
    kill "$QEMU_PID" 2>/dev/null || true
    wait "$QEMU_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

mkdir -p "$ASSETS" "$OUT"
if [ ! -f "$DEB" ]; then
  rm -f "$DEB.part"
  curl -fL --retry 3 --output "$DEB.part" "$URL"
  actual="$(sha256_file "$DEB.part")"
  if [ "$actual" != "$SHA256" ]; then
    rm -f "$DEB.part"
    echo "FATAL: U-Boot package checksum mismatch" >&2
    exit 1
  fi
  mv "$DEB.part" "$DEB"
fi
actual="$(sha256_file "$DEB")"
[ "$actual" = "$SHA256" ] || { echo "FATAL: U-Boot package checksum mismatch" >&2; exit 1; }
printf 'SHA256 OK  %s  %s\n' "$actual" "${DEB##*/}"

rm -rf "$OUT/uboot"
mkdir -p "$OUT/uboot"
(
  cd "$OUT/uboot"
  ar -x "$DEB"
  tar -xf data.tar.* usr/lib/u-boot/qemu-riscv64_smode/u-boot.bin
  cp usr/lib/u-boot/qemu-riscv64_smode/u-boot.bin "$UBOOT.part"
)
[ -s "$UBOOT.part" ] || { echo "FATAL: empty U-Boot binary" >&2; exit 1; }
mv "$UBOOT.part" "$UBOOT"

rm -f "$LOG" "$OUT/firmware.serial.log"
"$QEMU" \
  -machine virt -smp 1 -m 256M \
  -bios default -kernel "$UBOOT" \
  -display none -monitor none -serial "file:$OUT/firmware.serial.log" \
  -S -gdb "tcp:127.0.0.1:$GDB_PORT" &
QEMU_PID=$!

sleep 1
kill -0 "$QEMU_PID" 2>/dev/null || { echo "FATAL: QEMU exited before gdb connected" >&2; exit 1; }

"$GDB" -q -nx -batch \
  -ex 'set pagination off' \
  -ex 'set architecture riscv:rv64' \
  -ex "target remote 127.0.0.1:$GDB_PORT" \
  -ex 'printf "AT_RESET\n"' \
  -ex 'p/x $pc' \
  -ex 'break *0x80000000' \
  -ex 'continue' \
  -ex 'printf "AT_OPENSBI\n"' \
  -ex 'x/8i $pc' \
  -ex 'info registers a0 a1 pc' \
  -ex 'stepi' \
  -ex 'stepi' \
  -ex 'printf "AFTER_TWO_STEPS\n"' \
  -ex 'p/x $pc' \
  -ex 'disable 1' \
  -ex 'break *0x80200000' \
  -ex 'continue' \
  -ex 'printf "AT_UBOOT\n"' \
  -ex 'x/8i $pc' \
  -ex 'info registers a0 a1 pc' \
  -ex 'stepi' \
  -ex 'printf "AFTER_UBOOT_STEP\n"' \
  -ex 'x/2i $pc' \
  -ex 'info registers a0 a1 pc' \
  -ex 'p/x $pc' \
  -ex 'detach' 2>&1 | tee "$LOG"

grep -q 'AT_RESET' "$LOG"
grep -Eq '\$1 = 0x1000([[:space:]]|$)' "$LOG"
grep -q 'Breakpoint 1, 0x0000000080000000' "$LOG"
grep -Eq '\$2 = 0x80000008([[:space:]]|$)' "$LOG"
grep -q 'Breakpoint 2, 0x0000000080200000' "$LOG"
grep -q 'AFTER_UBOOT_STEP' "$LOG"
grep -Eq '\$3 = 0x80200002([[:space:]]|$)' "$LOG"
printf 'RESULT: PASS (reset, OpenSBI disassembly/registers/steps, U-Boot entry and step)\n'
