#!/usr/bin/env bash
# hostfwd 端口转发实验：QMP 看转发表 + 主机侧 lsof/nc 验证端口真的在监听，再做无转发阴性对照
# 依赖：qemu（含 qemu-system-riscv64）、nc、lsof（macOS 自带）
# 用法：./run.sh | tee run1.log
set -u

QEMU=qemu-system-riscv64
OUT=./output
mkdir -p "$OUT"

PIDS=()
cleanup() {
  for p in "${PIDS[@]:-}"; do kill "$p" 2>/dev/null || true; done
}
trap cleanup EXIT

echo '===== 0. 版本 ====='
"$QEMU" --version | head -1
echo

# start_vm <名称> <qemu 参数...>：设置全局 VM_PID / VM_SOCK
start_vm() {
  local name="$1"; shift
  VM_SOCK="$OUT/$name.sock"
  rm -f "$VM_SOCK"
  echo "+ $QEMU $*"
  "$QEMU" "$@" -qmp "unix:$VM_SOCK,server,nowait" -display none >/dev/null 2>&1 &
  VM_PID=$!
  PIDS+=("$VM_PID")
  for _ in $(seq 1 30); do
    [ -S "$VM_SOCK" ] && break
    sleep 0.3
  done
  sleep 0.8
}

qmp() {
  # 用法：qmp <sock> <HMP 命令>
  local sock="$1" cmd="$2"
  {
    printf '{"execute":"qmp_capabilities"}\n'; sleep 0.3
    printf '{"execute":"human-monitor-command","arguments":{"command-line":"%s"}}\n' "$cmd"; sleep 0.3
  } | nc -U "$sock"
}

stop_vm() {
  local pid="$1" sock="$2"
  {
    printf '{"execute":"qmp_capabilities"}\n'; sleep 0.3
    printf '{"execute":"quit"}\n'; sleep 0.3
  } | nc -U "$sock" >/dev/null
  for _ in $(seq 1 20); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.3
  done
  kill "$pid" 2>/dev/null || true
  rm -f "$sock"
}

echo '===== 1. 带两条 hostfwd 启动：2222->客户机 22，8080->客户机 80 ====='
start_vm 'fwd' \
  -machine virt -bios default -no-reboot \
  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
  -device virtio-net-device,netdev=net0
echo
echo '--- QMP 视角：info network 与 info usernet 的 HOST_FORWARD 转发表 ---'
qmp "$VM_SOCK" 'info network'
qmp "$VM_SOCK" 'info usernet'

echo
echo '===== 2. 主机视角：lsof 看到 qemu 进程监听 2222/8080，nc 探活成功 ====='
lsof -nP -iTCP:2222 -sTCP:LISTEN
lsof -nP -iTCP:8080 -sTCP:LISTEN
nc -z -G1 127.0.0.1 2222 && echo 'nc 127.0.0.1:2222 -> OPEN'
nc -z -G1 127.0.0.1 8080 && echo 'nc 127.0.0.1:8080 -> OPEN'

stop_vm "$VM_PID" "$VM_SOCK"
echo
echo '===== 3. 阴性对照：不带 hostfwd 的虚拟机存活期间，主机 2222 无人监听 ====='
start_vm 'nofwd' \
  -machine virt -bios default -no-reboot \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0
if nc -z -G1 127.0.0.1 2222 2>/dev/null; then
  echo '意外：2222 仍可连接'
else
  echo 'nc 127.0.0.1:2222 -> connection refused（预期：没有 hostfwd 就没有主机监听）'
fi
stop_vm "$VM_PID" "$VM_SOCK"
echo
echo '===== 全部步骤完成；产物在 output/（已 gitignore） ====='
