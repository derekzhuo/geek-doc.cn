#!/usr/bin/env bash
# 在 geek-eda:0.3-sta 容器内执行：两版 harness 的行/分支/翻转覆盖率采集与合并
set -e
rm -rf obj_dir obj_dir_full logs_partial logs_full logs_merged
rm -f coverage.dat partial.dat full.dat merged.dat

# 分指标统计：v_line 行/块、v_branch 分支、v_toggle 翻转
count_metrics() {
    tr '\002' '|' < "$1" | grep '^C ' \
        | sed -E 's/.*page[|](v_[a-z]+)\/.* ([0-9]+)$/\1 \2/' \
        | sort \
        | awk '{t[$1]++; if ($2==0) z[$1]++}
               END {for (k in t) printf "  %-9s covered %d/%d  (zero=%d)\n", k, t[k]-z[k], t[k], z[k]}'
}

verilator -V | head -3

echo "==================== [1/7] 编译：行覆盖 + 翻转覆盖（partial harness） ===================="
verilator --cc counter.v --exe tb_partial.cpp \
    --top-module counter \
    --coverage-line --coverage-toggle \
    --build -j 2

echo "==================== [2/7] 运行仿真，产出 coverage.dat 并归档为 partial.dat ===================="
./obj_dir/Vcounter
cp coverage.dat partial.dat
ls -l partial.dat

echo "==================== [3/7] partial：汇总 / 排名 / 源码注释 / 分指标计数 ===================="
verilator_coverage partial.dat
verilator_coverage --rank partial.dat
verilator_coverage --annotate logs_partial partial.dat
count_metrics partial.dat
echo "---- 注释后源码 logs_partial/counter.v（%000000 表示零命中） ----"
cat logs_partial/counter.v

echo "==================== [4/7] 补 load 激励，重新编译运行（full harness） ===================="
verilator --cc counter.v --exe tb_full.cpp \
    --top-module counter --Mdir obj_dir_full \
    --coverage-line --coverage-toggle \
    --build -j 2
./obj_dir_full/Vcounter
cp coverage.dat full.dat

echo "==================== [5/7] full：汇总 / 排名 / 源码注释 / 分指标计数 ===================="
verilator_coverage full.dat
verilator_coverage --rank full.dat
verilator_coverage --annotate logs_full full.dat
count_metrics full.dat
echo "---- 注释后源码 logs_full/counter.v ----"
cat logs_full/counter.v

echo "==================== [6/7] 合并两个用例：--write merged.dat 后再出报告 ===================="
verilator_coverage --write merged.dat partial.dat full.dat
verilator_coverage merged.dat
verilator_coverage --annotate logs_merged merged.dat
count_metrics merged.dat
echo "---- 合并后注释源码 logs_merged/counter.v ----"
cat logs_merged/counter.v

echo "==================== [7/7] coverage.dat 数据文件长什么样 ===================="
head -12 full.dat
