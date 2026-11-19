#!/usr/bin/env bash
# 公共函数：四组 gdbstub 连接实验共用的虚拟机起停与 gdb 批处理逻辑（macOS bash 3.2 可跑）
QEMU=qemu-system-riscv64
GDB=riscv64-elf-gdb
GDPPORT=1234

run() {
  echo "+ $*"
  "$@"
}

# 启动冻结在复位向量的虚拟机：start_qemu <output 目录> [是否开 gdbstub: on|off] [额外 qemu 参数...]
start_qemu() {
  local out="$1"; local stub="$2"; shift 2
  mkdir -p "$out"
  QMP_SOCK="$out/qmp.sock"
  rm -f "$QMP_SOCK"
  local stub_args=()
  if [ "$stub" = "on" ]; then
    stub_args=(-s -S)
  else
    stub_args=(-S)
  fi
  "$QEMU" -machine virt -bios default -display none \
    "${stub_args[@]}" -qmp "unix:$QMP_SOCK,server,nowait" "$@" >/dev/null 2>&1 &
  QEMU_PID=$!
  for _ in $(seq 1 30); do
    [ -S "$QMP_SOCK" ] || { sleep 0.3; continue; }
    if [ "$stub" = "on" ]; then
      nc -z -G1 127.0.0.1 "$GDPPORT" 2>/dev/null && break
      sleep 0.3
    else
      break
    fi
  done
}

stop_qemu() {
  kill "$QEMU_PID" 2>/dev/null || true
  wait "$QEMU_PID" 2>/dev/null || true
  rm -f "$QMP_SOCK"
}

# 批处理跑 gdb：gdb_session <架构参数...> -- <其余 gdb -ex 参数...>
gdb_session() {
  local arch="$1"; shift
  echo "+ $GDB -q -nx -batch -ex 'set architecture $arch' -ex 'target remote :$GDPPORT' ..."
  "$GDB" -q -nx -batch \
    -ex "set architecture $arch" \
    -ex "target remote :$GDPPORT" \
    "$@"
}
