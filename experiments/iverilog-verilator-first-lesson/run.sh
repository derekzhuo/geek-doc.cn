#!/usr/bin/env bash
# 同一份计数器 RTL 的双仿真器对照：
#   1) Icarus Verilog：iverilog 编译为 vvp 字节码，事件驱动执行 Verilog testbench；
#   2) Verilator：先 --binary 直接编译 RTL+testbench，再补一次显式 C++ 外壳流程，
#      展示它把 RTL 转成 C++ 再走系统编译器的链路。
# 两套轨迹仅差最后一拍的采样口径（测试平台用宏隔离各自预期）；
# 另跑 verilator --lint-only 展示前置静态检查。
set -euo pipefail
cd "$(dirname "$0")/rtl"

echo "== 工具版本 =="
iv_ver="$(iverilog -V 2>&1)" && echo "${iv_ver%%$'\n'*}"
vl_ver="$(verilator --version 2>&1)" && echo "${vl_ver%%$'\n'*}"
echo

echo "== 1. Icarus Verilog 事件驱动仿真 =="
iverilog -g2012 -o counter-iv.vvp counter.v tb_counter.v
vvp counter-iv.vvp
echo

echo "== 2. Verilator --binary 一体化编译仿真 =="
verilator --binary -j 2 --timing --build -Wno-fatal \
    counter.v tb_counter.v --top-module tb_counter
./obj_dir/Vtb_counter
echo

echo "== 3. Verilator lint-only 前置静态检查 =="
verilator --lint-only -Wall counter.v && echo "lint: counter.v 无告警"
echo

echo "== 4. 编译耗时对照（各 3 次，毫秒墙钟取中位）=="
for tool in iverilog verilator; do
    samples=()
    for k in 1 2 3; do
        t0=$(date +%s%3N)
        if [ "$tool" = iverilog ]; then
            iverilog -g2012 -o /tmp/counter-test.vvp counter.v tb_counter.v
        else
            rm -rf obj_dir
            verilator --binary -j 2 --timing --build -Wno-fatal \
                counter.v tb_counter.v --top-module tb_counter >/dev/null
        fi
        t1=$(date +%s%3N)
        ms=$((t1 - t0))
        samples+=("$ms")
        echo "$tool run$k: ${ms} ms"
    done
    med=$(printf '%s\n' "${samples[@]}" | sort -n | sed -n '2p')
    echo "$tool median: ${med} ms"
done
rm -f /tmp/counter-test.vvp
echo "done"
