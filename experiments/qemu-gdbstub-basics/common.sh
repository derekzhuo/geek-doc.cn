#!/usr/bin/env bash
# 公共函数：gdbstub 两脚本共用的起停与回显逻辑（macOS bash 3.2 可跑）
QEMU=qemu-system-riscv64
GDB=riscv64-elf-gdb
GDPPORT=1234

run() {
  echo "+ $*"
  "$@"
}

# 启动一台冻结在复位向量的虚拟机：-s 开 gdbstub(1234)，-S 启动后不跑指令
# 用法：start_qemu <output 目录> [额外 qemu 参数...]
start_qemu() {
  local out="$1"; shift
  QMP_SOCK="$out/qmp.sock"
  rm -f "$QMP_SOCK"
  "$QEMU" -machine virt -bios default -display none \
    -s -S -qmp "unix:$QMP_SOCK,server,nowait" "$@" >/dev/null 2>&1 &
  QEMU_PID=$!
  for _ in $(seq 1 30); do
    nc -z -G1 127.0.0.1 "$GDPPORT" 2>/dev/null && [ -S "$QMP_SOCK" ] && break
    sleep 0.3
  done
}

stop_qemu() {
  kill "$QEMU_PID" 2>/dev/null || true
  wait "$QEMU_PID" 2>/dev/null || true
  rm -f "$QMP_SOCK"
}

qmp_query() {
  {
    printf '{"execute":"qmp_capabilities"}\n'; sleep 0.3
    printf '{"execute":"query-status"}\n'; sleep 0.3
  } | nc -U "$QMP_SOCK"
}

# 批处理跑 gdb：gdb_session <gdb -ex 参数...>，自动补架构与连接
gdb_session() {
  echo "+ $GDB -q -nx -batch -ex 'set architecture riscv:rv64' -ex 'target remote :$GDPPORT' ..."
  "$GDB" -q -nx -batch \
    -ex 'set architecture riscv:rv64' \
    -ex "target remote :$GDPPORT" \
    "$@"
}
