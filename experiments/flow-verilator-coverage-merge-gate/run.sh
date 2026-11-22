#!/usr/bin/env bash
# 在 geek-eda:0.4-flow 容器内执行：
# 3 个种子各跑一份 coverage.dat -> verilator_coverage 合并 ->
# 文本汇总对照 -> 同一 merged 结果演示宽松/收紧两档阈值门禁
set -u
rm -rf obj_dir logs_merged
rm -f coverage.dat coverage_seed*.dat merged.dat report.info

verilator -V | head -3
echo "---- 报告工具可用性 ----"
if command -v genhtml >/dev/null 2>&1; then
    echo "genhtml: $(command -v genhtml)"
else
    echo "genhtml: NOT FOUND in this image"
fi
if command -v lcov >/dev/null 2>&1; then
    echo "lcov: $(command -v lcov)"
else
    echo "lcov: NOT FOUND in this image"
fi

echo "==================== [1/6] 编译带覆盖率插桩的仿真（一次编译，三个种子复用） ===================="
verilator --cc rtl/counter.v --exe sim/tb.cpp \
    --top-module counter \
    --coverage-line --coverage-toggle \
    --build -j 1

echo "==================== [2/6] 三个种子分别运行，各写一份 coverage_seedN.dat ===================="
for seed in 1 2 3; do
    ./obj_dir/Vcounter "$seed"
done
ls -l coverage_seed*.dat

echo "==================== [3/6] 单种子覆盖率：--rank 排名 + 分指标计数 ===================="
for seed in 1 2 3; do
    echo "---- seed $seed: verilator_coverage --rank ----"
    verilator_coverage --rank "coverage_seed${seed}.dat"
    echo "---- seed $seed: 分指标（行/分支/翻转） ----"
    bash scripts/coverage_summary.sh "coverage_seed${seed}.dat"
done

echo "==================== [4/6] 合并三份数据：--write merged.dat 后再出汇总 ===================="
verilator_coverage --write merged.dat coverage_seed1.dat coverage_seed2.dat coverage_seed3.dat
echo "---- merged: verilator_coverage --rank ----"
verilator_coverage --rank merged.dat
echo "---- merged: 分指标（行/分支/翻转） ----"
bash scripts/coverage_summary.sh merged.dat
echo "---- merged: --annotate 逐行注释（%000000 表示零命中） ----"
verilator_coverage --annotate logs_merged merged.dat
cat logs_merged/counter.v

echo "==================== [5/6] lcov 信息文件导出（genhtml 不在镜像内，只演示到 .info） ===================="
verilator_coverage -write-info report.info merged.dat
ls -l report.info
head -8 report.info

echo "==================== [6/6] 阈值门禁：同一 merged 结果，宽松阈值通过、收紧阈值失败 ===================="
set +e
python3 scripts/coverage_gate.py merged.dat 70
rc_loose=$?
echo "gate rc=$rc_loose (threshold 70%)"
python3 scripts/coverage_gate.py merged.dat 90
rc_tight=$?
echo "gate rc=$rc_tight (threshold 90%)"
set -e

echo "==================== run.sh finished: rc_loose=$rc_loose rc_tight=$rc_tight ===================="
