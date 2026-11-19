#!/usr/bin/env bash
# 复现「QEMU 启动后终端黑屏/无串口输出」的四类现场，每类同时取两份证据：
# 终端侧 OpenSBI 横幅计数 + QMP query-chardev/query-status 的结构化状态。
#   1. vc-backend   漏接串口：-display none 且不用 -nographic，serial0 默认挂虚拟控制台 vc
#   2. serial-file  串口接文件：输出进文件，终端静默，文件里有完整横幅
#   3. cpu-frozen   CPU 冻结：-S 接线正确但一条指令没跑，query-status=prelaunch
#   4. stdio-conflict monitor 抢占 stdio：两个字符设备抢 stdio，QEMU 直接报错退出
set -u
QEMU=qemu-system-riscv64
OUT=./output
mkdir -p "$OUT"
exec 2>&1

printf 'TOOL_VERSION: '
"$QEMU" --version | head -1

qmp_call() {
  local sock="$1"; shift
  {
    printf '{"execute":"qmp_capabilities"}\n'; sleep 0.3
    for cmd in "$@"; do
      printf '%s\n' "$cmd"; sleep 0.3
    done
    printf '{"execute":"quit"}\n'; sleep 0.3
  } | nc -U "$sock"
}

echo
echo '===== 1. vc-backend：漏接串口，serial0 默认挂 vc，终端收不到任何字节 ====='
rm -f "$OUT/c1.sock" "$OUT/c1-stdio.txt"
"$QEMU" -machine virt -bios default -display none \
  -qmp "unix:$OUT/c1.sock,server,nowait" >"$OUT/c1-stdio.txt" 2>&1 &
P=$!
for _ in $(seq 1 20); do [ -S "$OUT/c1.sock" ] && break; sleep 0.3; done
sleep 0.5
qmp_call "$OUT/c1.sock" '{"execute":"query-chardev"}' | grep -o '"label": "[a-z0-9]*"\|"filename": "[^"]*"'
wait "$P" 2>/dev/null || true
echo "终端侧 OpenSBI 横幅计数：$(grep -c OpenSBI "$OUT/c1-stdio.txt")（serial0->vc，输出在不存在的图形窗口里）"

echo
echo '===== 2. serial-file：串口写文件，终端静默，横幅完整落盘 ====='
rm -f "$OUT/c2.sock" "$OUT/c2-stdio.txt" "$OUT/c2-serial.log"
"$QEMU" -machine virt -bios default -display none -serial "file:$OUT/c2-serial.log" \
  -qmp "unix:$OUT/c2.sock,server,nowait" >"$OUT/c2-stdio.txt" 2>&1 &
P=$!
for _ in $(seq 1 20); do [ -S "$OUT/c2.sock" ] && break; sleep 0.3; done
sleep 0.5
qmp_call "$OUT/c2.sock" '{"execute":"query-chardev"}' | grep -o '"label": "[a-z0-9]*"\|"filename": "[^"]*"'
wait "$P" 2>/dev/null || true
echo "终端侧横幅计数：$(grep -c OpenSBI "$OUT/c2-stdio.txt")；文件内横幅计数：$(grep -c OpenSBI "$OUT/c2-serial.log")"

echo
echo '===== 3. cpu-frozen：-S 冻结 CPU，接线是 stdio 但 prelaunch 状态零输出 ====='
rm -f "$OUT/c3.sock" "$OUT/c3-stdio.txt"
"$QEMU" -machine virt -bios default -nographic -S \
  -qmp "unix:$OUT/c3.sock,server,nowait" >"$OUT/c3-stdio.txt" 2>&1 &
P=$!
for _ in $(seq 1 20); do [ -S "$OUT/c3.sock" ] && break; sleep 0.3; done
sleep 0.5
qmp_call "$OUT/c3.sock" '{"execute":"query-status"}' '{"execute":"query-chardev"}' | grep -o '"status": "[a-z-]*"\|"label": "serial0"\|"filename": "stdio"'
wait "$P" 2>/dev/null || true
echo "终端侧横幅计数：$(grep -c OpenSBI "$OUT/c3-stdio.txt")（接线正确，CPU 没跑，固件自然没吐字）"

echo
echo '===== 4. stdio-conflict：-nographic 已占 stdio，再挂 -monitor stdio 直接冲突退出 ====='
"$QEMU" -machine virt -bios default -nographic -monitor stdio </dev/null
printf 'CASE_EXIT stdio_conflict=%s（QEMU 启动即失败，两条报错见上）\n' "$?"

echo
echo '全部四组完成：无输出先 query-chardev 查接线后端，接线正确再 query-status 查 CPU 是否在跑，最后排查 stdio 复用冲突。'
