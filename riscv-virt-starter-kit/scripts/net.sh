#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=common.sh
source "$ROOT/scripts/common.sh"

need_cmd "$QEMU"
need_cmd ssh
trap 'stop_vm; release_lock' EXIT
start_vm net

SSH_OPTS=(-i "$OUT/id_ed25519" -p "$SSH_PORT" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 -o ConnectionAttempts=1)
printf 'Waiting for SSH on 127.0.0.1:%s\n' "$SSH_PORT"
ready=0
for n in $(seq 1 180); do
  if ssh "${SSH_OPTS[@]}" ubuntu@127.0.0.1 true >/dev/null 2>&1; then
    ready=1
    break
  fi
  kill -0 "$VM_PID" 2>/dev/null || break
  sleep 2
done
[ "$ready" -eq 1 ] || { tail -n 50 "$VM_SERIAL" >&2; fail "SSH did not become ready"; }

ssh "${SSH_OPTS[@]}" ubuntu@127.0.0.1 \
  'echo GUEST_SHELL_OK; printf "architecture="; uname -m; printf "kernel="; uname -r; printf "hostname="; hostname; printf "cloud-init="; cloud-init status 2>/dev/null || true' \
  2>&1 | tee "$OUT/net.log"
grep -q 'architecture=riscv64' "$OUT/net.log" || fail "guest architecture did not match"
printf 'RESULT: PASS (SSH hostfwd and guest command)\n'
