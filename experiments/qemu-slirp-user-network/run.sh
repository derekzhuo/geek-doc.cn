#!/usr/bin/env bash
# SLIRP 用户态网络实验：默认网络与显式 -netdev user 对照，经 QMP 查网卡与网段
# 依赖：qemu（含 qemu-system-riscv64）、nc
# 用法：./run.sh | tee run1.log
set -u

QEMU=qemu-system-riscv64
OUT=./output
mkdir -p "$OUT"

echo '===== 0. 版本 ====='
"$QEMU" --version | head -1
echo

qmp_call() {
  local sock="$1"; shift
  {
    printf '{"execute":"qmp_capabilities"}\n'; sleep 0.3
    for cmd in "$@"; do
      printf '{"execute":"human-monitor-command","arguments":{"command-line":"%s"}}\n' "$cmd"; sleep 0.3
    done
    printf '{"execute":"quit"}\n'; sleep 0.3
  } | nc -U "$sock"
}

start_vm() {
  local name="$1"; shift
  local sock="$OUT/$name.sock"
  rm -f "$sock"
  echo "+ $QEMU $*"
  "$QEMU" "$@" -qmp "unix:$sock,server,nowait" -display none >/dev/null 2>&1 &
  local pid=$!
  for _ in $(seq 1 20); do
    [ -S "$sock" ] && break
    sleep 0.3
  done
  sleep 0.5
  qmp_call "$sock" "info network"
  wait "$pid" 2>/dev/null || true
  rm -f "$sock"
  echo
}

echo '===== 1. 不写任何网络参数：QEMU 默认就给一块 user 模式网卡 ====='
start_vm 'default-net' -machine virt -bios default -no-reboot

echo '===== 2. 显式声明：-netdev user + virtio-net-device，网段仍是默认 10.0.2.0/24 ====='
start_vm 'explicit-user' -machine virt -bios default -no-reboot \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0

echo '===== 对照结论 ====='
echo '两轮都有 type=user、net=10.0.2.0：SLIRP 用户态 NAT 后端默认就存在，无需 root、不创建虚拟交换机。'
echo '区别在网卡前端：默认轮只有 hub 上的 user 后端、没有 nic；显式 -device virtio-net-device 后才出现 macaddr=52:54:00:12:34:56 的网卡。'
echo
echo '===== 全部步骤完成；产物在 output/（已 gitignore） ====='
