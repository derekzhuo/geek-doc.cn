#!/bin/sh
# 复现脚本：三种数组写法在存储器推断各阶段的 stat 对照
# 用法：sh run.sh   （需本机有 geek-eda:0.3-sta 镜像）
DIR=$(dirname "$0")
cd "$DIR"

YOSYS="docker run --rm -v $PWD:/work -w /work geek-eda:0.3-sta yosys"

echo "### yosys -V"
$YOSYS -V

echo "### help memory"
$YOSYS -p 'help memory' || true

echo "### help synth_ice40 (memory related lines)"
$YOSYS -p 'help synth_ice40' | grep -Ei 'memory|bram|nomap' || true

for top in ram_sync ram_async ram_flat; do
    echo "############################################################"
    echo "### module: $top"
    echo "############################################################"
    $YOSYS -p "
read_verilog rtl.v
hierarchy -top $top
log [STAGE 1] after hierarchy: processes / memories 还在前端形态
stat
proc
opt_clean
log [STAGE 2] after proc+opt: 数组是 memrd/memwr 单元
stat
memory -nomap
log [STAGE 3] after memory -nomap: 粗粒度 mem_v2
stat
memory_map
opt_clean
log [STAGE 4] after memory_map: 摊平为门级 DFF/MUX
stat
"
done
