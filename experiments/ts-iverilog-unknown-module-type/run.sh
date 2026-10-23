#!/bin/sh
# 复现 iverilog "error: Unknown module type" 及修复
set -x
cd "$(dirname "$0")"

# 1) 报错版：漏传 sub_adder.v
iverilog -g2012 -o top.vvp top_use_adder.v
echo "err exit=$?"

# 2) 修复版：补传子模块文件
iverilog -g2012 -o top.vvp top_use_adder.v sub_adder.v && vvp top.vvp
echo "fix exit=$?"
