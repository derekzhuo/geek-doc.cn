#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="$ROOT/assets"
OUT="$ROOT/output"
QEMU="${QEMU:-qemu-system-riscv64}"
QEMU_IMG="${QEMU_IMG:-qemu-img}"
GDB="${GDB:-riscv64-elf-gdb}"
IMAGE="$ASSETS/noble-server-cloudimg-riscv64.img"
UBOOT="$ASSETS/u-boot-riscv64.bin"
SSH_PORT="${SSH_PORT:-2222}"
GDB_PORT="${GDB_PORT:-1234}"
MEMORY="${MEMORY:-2048}"
CPUS="${CPUS:-2}"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

acquire_lock() {
  mkdir -p "$OUT"
  if ! mkdir "$OUT/.lock" 2>/dev/null; then
    [ -r "$OUT/.lock/pid" ] || fail "a starter-kit lock is being initialized; retry shortly"
    owner="$(tr -d '[:space:]' < "$OUT/.lock/pid")"
    case "$owner" in ''|*[!0-9]*) fail "invalid lock owner; inspect output/.lock/pid" ;; esac
    if kill -0 "$owner" 2>/dev/null; then
      fail "starter-kit command PID $owner is still using output/"
    fi
    rm -f "$OUT/.lock/pid"
    rmdir "$OUT/.lock" 2>/dev/null || fail "lock ownership changed during stale-lock recovery"
    mkdir "$OUT/.lock" 2>/dev/null || fail "another starter-kit command acquired output/ first"
  fi
  LOCK_DIR="$OUT/.lock"
  printf '%s\n' "$$" > "$LOCK_DIR/pid"
}

release_lock() {
  [ -n "${LOCK_DIR:-}" ] || return 0
  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR" 2>/dev/null || true
  LOCK_DIR=
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d ' ' -f 1
  else
    sha256sum "$1" | cut -d ' ' -f 1
  fi
}

create_seed() {
  need_cmd ssh-keygen
  mkdir -p "$OUT/seed"
  if [ ! -f "$OUT/id_ed25519" ]; then
    ssh-keygen -q -t ed25519 -N '' -f "$OUT/id_ed25519"
  fi
  local pubkey
  pubkey="$(cut -d ' ' -f 1,2 "$OUT/id_ed25519.pub")"
  cat > "$OUT/seed/user-data" <<EOF
#cloud-config
hostname: riscv-virt
users:
  - name: ubuntu
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: \$6\$riscvkit\$6CBsOo6MISbzYCNebA30GhIwYDeIcwUuG4gIu.4Ez0TU0Fgu5m/qG90gEyYp0X9MP4a0wpjv6V0EP96nH3MM.1
    ssh_authorized_keys:
      - $pubkey
ssh_pwauth: true
EOF
  cat > "$OUT/seed/meta-data" <<'EOF'
instance-id: riscv-virt-starter-kit-001
local-hostname: riscv-virt
EOF
  cat > "$OUT/seed/network-config" <<'EOF'
version: 2
ethernets:
  uplink:
    match:
      name: "e*"
    dhcp4: true
EOF
  rm -f "$OUT/seed.iso"
  if command -v hdiutil >/dev/null 2>&1; then
    hdiutil makehybrid -iso -joliet -default-volume-name CIDATA -o "$OUT/seed.iso" "$OUT/seed" >/dev/null
  elif command -v genisoimage >/dev/null 2>&1; then
    genisoimage -quiet -output "$OUT/seed.iso" -volid CIDATA -joliet -rock "$OUT/seed"
  elif command -v xorriso >/dev/null 2>&1; then
    xorriso -as mkisofs -output "$OUT/seed.iso" -volid CIDATA -joliet -rock "$OUT/seed" >/dev/null 2>&1
  else
    fail "install genisoimage or xorriso to create the NoCloud seed"
  fi
}

create_overlay() {
  [ -f "$IMAGE" ] || fail "run make fetch first"
  [ -f "$UBOOT" ] || fail "run make fetch first"
  mkdir -p "$OUT"
  rm -f "$OUT/vm.qcow2"
  "$QEMU_IMG" create -q -f qcow2 -F qcow2 -b "$IMAGE" "$OUT/vm.qcow2"
}

start_vm() {
  local name="$1"
  need_cmd "$QEMU"
  need_cmd "$QEMU_IMG"
  acquire_lock
  VM_SERIAL="$OUT/$name.serial.log"
  VM_QMP="$OUT/$name.qmp.sock"
  rm -f "$VM_SERIAL" "$VM_QMP"
  create_seed
  create_overlay
  "$QEMU" \
    -machine virt -m "$MEMORY" -smp "$CPUS" \
    -bios default -kernel "$UBOOT" \
    -drive file="$OUT/vm.qcow2",if=virtio,format=qcow2 \
    -drive file="$OUT/seed.iso",if=virtio,format=raw,readonly=on \
    -netdev user,id=net0,hostfwd=tcp:127.0.0.1:"$SSH_PORT"-:22 \
    -device virtio-net-device,netdev=net0 \
    -display none -serial "file:$VM_SERIAL" -monitor none \
    -qmp "unix:$VM_QMP,server,nowait" -no-reboot &
  VM_PID=$!
  sleep 1
  kill -0 "$VM_PID" 2>/dev/null || fail "QEMU exited during startup; see $VM_SERIAL"
}

stop_vm() {
  if [ -n "${VM_PID:-}" ] && kill -0 "$VM_PID" 2>/dev/null; then
    kill -INT "$VM_PID" 2>/dev/null || true
    local n=0
    while kill -0 "$VM_PID" 2>/dev/null && [ "$n" -lt 20 ]; do
      sleep 0.2
      n=$((n + 1))
    done
    kill "$VM_PID" 2>/dev/null || true
  fi
  if [ -n "${VM_PID:-}" ]; then
    wait "$VM_PID" 2>/dev/null || true
  fi
}

run_with_timeout() {
  local seconds="$1"
  shift
  "$@" &
  local pid=$!
  local n=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$n" -ge "$seconds" ]; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    n=$((n + 1))
  done
  wait "$pid"
}
