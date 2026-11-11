#!/usr/bin/env bash
# 容器内（或本机 Verilator 5.x）实际执行：无开关对比 -> 断言拦下 -> 修复复跑
set -uo pipefail
rm -rf build_noassert build_bad build_fixed
mkdir -p build_noassert build_bad build_fixed
verilator -V | head -1

echo "=== STEP 1/3: 不加 --assert，满写违规被静默放过 ==="
verilator --cc --exe -Wno-fatal --top-module fifo \
  -Mdir build_noassert fifo.sv tb_bad.cpp
make -C build_noassert -f Vfifo.mk -j2 >/dev/null
./build_noassert/Vfifo
echo "step1 exit=$?  <-- 0 不代表设计正确，断言根本没编译进去"

echo "=== STEP 2/3: 加 --assert，同一 harness 在第 5 拍被拦下 ==="
verilator --cc --exe --assert -Wno-fatal --top-module fifo \
  -Mdir build_bad fifo.sv tb_bad.cpp
make -C build_bad -f Vfifo.mk -j2 >/dev/null
./build_bad/Vfifo
echo "step2 exit=$?  <-- 134 = SIGABRT，断言失败中止仿真"

echo "=== STEP 3/3: 修复 harness（尊重 full 反压），断言全开复跑 ==="
verilator --cc --exe --assert -Wno-fatal --top-module fifo \
  -Mdir build_fixed fifo.sv tb_fixed.cpp
make -C build_fixed -f Vfifo.mk -j2 >/dev/null
./build_fixed/Vfifo
echo "step3 exit=$?"

echo "=== STEP 4 (附录): assert property 里的 ## 周期延迟在 5.020 编译期被拒 ==="
verilator --lint-only --assert sva_subset_delay.sv \
  && echo "UNEXPECTED: delayed sequence compiled" \
  || echo "note: above UNSUPPORTED is the SVA subset boundary, expected"
