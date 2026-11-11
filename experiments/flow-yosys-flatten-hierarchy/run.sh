#!/usr/bin/env bash
# 一键复现：flatten 前后 stat / write_verilog / select 对照
# 在 geek-eda:0.4-flow 容器内执行
set -u
cd "$(dirname "$0")"

echo "================ 0. 工具版本 ================"
yosys -V

echo
echo "================ 1. 保留 hierarchy：hierarchy; proc; opt 后 stat ================"
yosys -p "read_verilog sub.v top.v; hierarchy -top top; proc; opt; stat"

echo
echo "================ 2. 保留 hierarchy：写出网表模块清单与例化行 ================"
yosys -p "read_verilog sub.v top.v; hierarchy -top top; proc; opt; write_verilog -noattr net_hier.v"
echo "--- net_hier.v 中的 module 声明 ---"
grep -n "^module" net_hier.v
echo "--- top 内部对 sub 子模块的例化（前 6 行） ---"
grep -n "u_inst" net_hier.v | head -6

echo
echo "================ 3. 保留 hierarchy：按子模块名单独 stat ================"
yosys -p "read_verilog sub.v top.v; hierarchy -top top; proc; opt; stat sub"

echo
echo "================ 4. flatten 后：stat ================"
yosys -p "read_verilog sub.v top.v; hierarchy -top top; proc; opt; flatten; stat"

echo
echo "================ 5. flatten 后：写出网表模块清单与层级线网名 ================"
yosys -p "read_verilog sub.v top.v; hierarchy -top top; proc; opt; flatten; write_verilog -noattr net_flat.v"
echo "--- net_flat.v 中的 module 声明 ---"
grep -n "^module" net_flat.v
echo "--- 网表中带层级路径的线网名（前 10 个，去重） ---"
grep -oE '\\g\[[0-9]+\]\.u_inst\.[A-Za-z_]+' net_flat.v | sort -u | head -10

echo
echo "================ 6. flatten 后：还能按子模块名 stat 吗 ================"
yosys -p "read_verilog sub.v top.v; hierarchy -top top; proc; opt; flatten; stat sub"

echo
echo "================ 7. 默认 synth 流程中与 hierarchy/flatten 相关的行 ================"
yosys -p "read_verilog sub.v top.v; synth -top top" 2>&1 | grep -iE "hierarchy|flatten"

echo
echo "================ 8. synth -flatten 中与 hierarchy/flatten 相关的行 ================"
yosys -p "read_verilog sub.v top.v; synth -top top -flatten" 2>&1 | grep -iE "hierarchy|flatten"
