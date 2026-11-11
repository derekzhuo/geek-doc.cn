#!/usr/bin/env bash
# 三模块工程（alu + regfile + datapath）+ tb：三种文件组织方式实测
set -u
cd "$(dirname "$0")"
mkdir -p build

echo "===== toolchain ====="
iverilog -V 2>/dev/null | head -1

echo
echo "===== way1: 命令行直接列出全部文件 ====="
iverilog -g2012 -Wall -o build/sim_cli.vvp rtl/alu.v rtl/regfile.v rtl/datapath.v tb/tb_top.v && vvp build/sim_cli.vvp

echo
echo "===== way1b: 颠倒文件顺序（tb 在最前、被依赖模块在最后）====="
iverilog -g2012 -Wall -o build/sim_rev.vvp tb/tb_top.v rtl/datapath.v rtl/regfile.v rtl/alu.v && vvp build/sim_rev.vvp

echo
echo "===== way2: -f 读取文件清单 filelist.f ====="
iverilog -g2012 -Wall -o build/sim_flist.vvp -f filelist.f && vvp build/sim_flist.vvp

echo
echo "===== way3: -y 库目录（命令行只给 tb，子模块按模块名自动检索）====="
iverilog -g2012 -Wall -o build/sim_lib.vvp -y rtl tb/tb_top.v && vvp build/sim_lib.vvp

echo
echo "===== checkpoint A: 不列库文件也不给 -y 时的报错（预期失败）====="
iverilog -g2012 -o build/sim_miss.vvp tb/tb_top.v; echo "exit=$?"

echo
echo "===== checkpoint B: 同一文件列两遍（预期 duplicate module 报错）====="
iverilog -g2012 -o build/sim_dup.vvp rtl/alu.v rtl/alu.v rtl/regfile.v rtl/datapath.v tb/tb_top.v; echo "exit=$?"
