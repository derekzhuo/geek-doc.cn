#!/usr/bin/env bash
# Yosys 内建 sat 形式证明实验（只用 yosys，不依赖 sby）：
#   1) 组合属性：正确式恒成立（SUCCESS），注入错误后给出反例（FAIL + 输入赋值）；
#   2) 时序属性：两个计数器的逐拍相等性，扫证明深度 1..4，
#      错误实现在深度 1 假通过、深度 >=2 才被反例抓出；
# 注意：sat 证明失败时 yosys 进程退出码仍是 0，成败必须解析
# 「SAT proof finished ... SUCCESS/FAIL」判定行，不能只看 \$?。
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p build

echo '$ bash run.sh'
echo "== 0. 工具版本 =="
yosys -V
echo

echo "== 1. 组合属性证明：-set-def-inputs 让输入自由取值，证明 eq 恒为 1 =="
echo "-- 1a. 正确实现 prop_good（y2 == ~y1 恒成立）--"
yosys -p "read_verilog rtl/prop_good.v; sat -set-def-inputs -prove eq 1 prop_good" 2>&1 | tee build/comb_good.log | grep -E "SAT proof"
echo "yosys 退出码=${PIPESTATUS[0]}（注意：证明成败不体现在退出码）"
echo
echo "-- 1b. 注入错误 prop_bad（异或被写成与，期望 FAIL 并给反例）--"
yosys -p "read_verilog rtl/prop_bad.v; sat -set-def-inputs -prove eq 1 prop_bad" 2>&1 | tee build/comb_bad.log | grep -E "SAT proof|Signal Name|\\\\a|\\\\b|eq"
echo "yosys 退出码=${PIPESTATUS[0]}"
echo

echo "== 2. 时序属性证明：两计数器逐拍相等，扫深度 seq=1..4 =="
for mod in seq_good seq_bad; do
  echo "-- 2.$([ "$mod" = seq_good ] && echo a || echo b) 模块 ${mod} --"
  for n in 1 2 3 4; do
    verdict=$(yosys -p "read_verilog rtl/${mod}.v; proc; sat -seq ${n} -prove eq 1 ${mod}" 2>&1 | tee build/${mod}_seq${n}.log | grep -E "SAT proof")
    echo "seq=${n}: ${verdict}"
  done
  echo
done

echo "== 3. seq_bad 在 seq=4 下的完整反例表（按时间步给出信号取值）=="
sed -n '/Solving problem/,/End of script/p' build/seq_bad_seq4.log | head -25
echo

echo "== 4. 判定汇总（从日志提取 verdict，不看退出码）=="
for f in build/comb_good.log build/comb_bad.log build/seq_good_seq1.log build/seq_good_seq4.log build/seq_bad_seq1.log build/seq_bad_seq4.log; do
  printf '%-28s %s\n' "$f" "$(grep -oE 'SAT proof finished - .*(SUCCESS|FAIL)!' "$f")"
done
echo "done"
