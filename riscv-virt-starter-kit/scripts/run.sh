#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$ROOT/scripts/common.sh"

need_cmd "$QEMU"
need_cmd "$QEMU_IMG"
acquire_lock
trap release_lock EXIT
create_seed
create_overlay

printf '\nLogin: ubuntu / riscv\n'
printf 'SSH after boot: ssh -i output/id_ed25519 -p %s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@127.0.0.1\n' "$SSH_PORT"
printf 'Quit console: Ctrl-a x\n\n'

"$QEMU" \
  -machine virt -m "$MEMORY" -smp "$CPUS" \
  -bios default -kernel "$UBOOT" \
  -drive file="$OUT/vm.qcow2",if=virtio,format=qcow2 \
  -drive file="$OUT/seed.iso",if=virtio,format=raw,readonly=on \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:"$SSH_PORT"-:22 \
  -device virtio-net-device,netdev=net0 \
  -nographic -no-reboot
