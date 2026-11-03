#!/usr/bin/env bash
# flow-iverilog-g2012-sv 探针总跑脚本
# 对 features/ 下每个最小片段用 iverilog -g2012 真编译、vvp 真跑；
# 失败片段是预期内的「支持范围」证据，保留真实报错原文。
set +e
cd "$(dirname "$0")"
IVERILOG=${IVERILOG:-/usr/local/bin/iverilog}
VVP=${VVP:-/usr/local/bin/vvp}

echo "# command: bash run.sh (features/*.sv, iverilog -g2012 + vvp)"
echo "# date: 2026-11-04"
echo "# host-toolchain: Icarus Verilog 13.0 (native macOS)"
echo
echo "== toolchain version =="
$IVERILOG -V 2>&1 | grep -vE 'Unable to get version|/var/folders|Cellar' | head -3
$VVP -V 2>&1 | grep -vE 'Unable to get version|/var/folders|Cellar' | head -1
echo

run_one() {
  local f="$1"; local stem; stem=$(basename "$f" .sv)
  echo "----- [$stem] iverilog -g2012 -o /tmp/${stem}.vvp $f"
  if $IVERILOG -g2012 -Wall -o "/tmp/${stem}.vvp" "$f" 2>&1; then
    echo "----- [$stem] compile OK, run vvp"
    $VVP "/tmp/${stem}.vvp" 2>&1
    echo "----- [$stem] vvp exit=$?"
  else
    echo "----- [$stem] COMPILE REJECTED (exit=$?), expected-range evidence kept"
  fi
  echo
}

echo "########## A. -g2012 下逐个特性探针 ##########"
for f in features/*.sv; do
  run_one "$f"
done

echo "########## B. 对照：不带 -g2012（默认标准）编译同一批片段 ##########"
echo "----- [01_logic] iverilog (no -g flag) features/01_logic.sv"
$IVERILOG -o /tmp/nog2012.vvp features/01_logic.sv 2>&1
echo "----- [01_logic] default-mode exit=$? (logic 关键字在默认模式被容忍)"
echo
echo "----- [02_always_ff] iverilog (no -g flag) features/02_always_ff.sv"
$IVERILOG -o /tmp/nog2012.vvp features/02_always_ff.sv 2>&1
echo "----- [02_always_ff] default-mode exit=$? (SV 过程块关键字被拒绝)"
echo
echo "----- [06_enum] iverilog (no -g flag) features/06_enum.sv"
$IVERILOG -o /tmp/nog2012.vvp features/06_enum.sv 2>&1
echo "----- [06_enum] default-mode exit=$?"
echo
echo "########## DONE ##########"
