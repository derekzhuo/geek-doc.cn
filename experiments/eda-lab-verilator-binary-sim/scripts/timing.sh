#!/bin/bash
# timing.sh —— 同一份 TB 分别用 vvp 与 verilator 二进制各跑 $RUNS 次，记录 real 秒数。
# 用法：RUNS=3 bash scripts/timing.sh <cycles>
# 输出：标准输出（由 Makefile tee 到 out/timing.log）
# 说明：容器里没有 /usr/bin/time（ubuntu:24.04 最小镜像），用 bash 内建 time + TIMEFORMAT。

set -u
CYCLES=${1:-10000000}
RUNS=${RUNS:-3}
TIMEFORMAT=%R

SIMV=out/counter_sim.vvp
VBIN=obj_dir/Vcounter_tb

echo "# verilator --binary vs iverilog 速度实测 ($(date '+%Y-%m-%d %H:%M:%S'))"
echo "# 环境: $(iverilog -V 2>/dev/null | head -1) / $(verilator --version)"
echo "# 仿真拍数: ${CYCLES}，每个仿真器跑 ${RUNS} 次取中位数"
echo ""

run_n() {
    # $1 = 名称, $2... = 命令；打印每次 real 秒，输出中位数行
    local name=$1; shift
    local times=() t st i med
    for (( i=1; i<=RUNS; i++ )); do
        t=$( { time "$@" > "out/run_${name}_${i}.log" 2>&1; } 2>&1 )
        if grep -q "TEST PASS" "out/run_${name}_${i}.log"; then st=PASS; else st=FAIL; fi
        echo "${name} run${i}: ${t}s (${st})"
        times+=("$t")
    done
    med=$(printf '%s\n' "${times[@]}" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
    echo "${name} median: ${med}s"
    echo "$med" > "out/${name}_median.txt"
}

run_n iverilog vvp "$SIMV"
run_n verilator "$VBIN"

iv=$(cat out/iverilog_median.txt)
vl=$(cat out/verilator_median.txt)
speedup=$(awk -v a="$iv" -v b="$vl" 'BEGIN{printf "%.1f", a/b}')
echo ""
echo "speedup (iverilog_median / verilator_median): ${speedup}x"
