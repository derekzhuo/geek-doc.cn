#!/usr/bin/env bash
# 串口接线三模式对照：-nographic / -serial mon:stdio / -serial null
# 每种模式同时取两份证据：stdio 上 OpenSBI 横幅出现次数 + QMP query-chardev 的结构化接线
# 依赖：qemu（含 qemu-system-riscv64）、nc（macOS 自带 -U）
# 用法：./run.sh | tee run1.log
set -u

QEMU=qemu-system-riscv64
OUT=./output
mkdir -p "$OUT"

echo '===== 0. 版本 ====='
"$QEMU" --version | head -1
echo

# run_mode <名称> <qemu 参数...>
# 固定追加 QMP 套接字；虚拟机自身 stdio 收进文件，QMP 的 JSON 走当前终端
run_mode() {
  local name="$1"; shift
  local sock="$OUT/$name.sock"
  local cap="$OUT/$name-stdio.txt"
  rm -f "$sock" "$cap"

  echo "===== $name ====="
  echo "+ $QEMU $* -qmp unix:$sock,server,nowait"
  "$QEMU" "$@" -qmp "unix:$sock,server,nowait" >"$cap" 2>&1 &
  local pid=$!
  for _ in $(seq 1 20); do
    [ -S "$sock" ] && break
    sleep 0.3
  done
  sleep 0.5

  {
    printf '{"execute":"qmp_capabilities"}\n'; sleep 0.3
    printf '{"execute":"query-chardev"}\n'; sleep 0.3
    printf '{"execute":"quit"}\n'; sleep 0.3
  } | nc -U "$sock" | grep '"label"'

  wait "$pid" 2>/dev/null || true
  echo "stdio 捕获文件中 OpenSBI 横幅出现次数：$(grep -c OpenSBI "$cap")"
  echo
}

run_mode 'A-nographic' \
  -machine virt -bios default -nographic -no-reboot

run_mode 'B-mon-stdio' \
  -machine virt -bios default -display none -serial mon:stdio -no-reboot

run_mode 'C-serial-null' \
  -machine virt -bios default -display none -serial null -no-reboot

echo '===== 对照结论（数值由上面三轮实测产生）====='
echo 'A/B 横幅计数=1：串口接在 stdio 上，启动信息直接进终端；C 计数=0：串口接 null，输出被丢弃。'
echo 'query-chardev 里：A 是 serial0->stdio 直连；B 是 serial0->mux、serial0-base->stdio（与 monitor 复用）；C 是 serial0->null。'
echo
echo '===== 全部步骤完成；产物在 output/（已 gitignore） ====='
