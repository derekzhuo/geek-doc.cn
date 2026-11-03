#!/usr/bin/env bash
# flat vs hierarchical Verilation benchmark (Verilator 5.020)
set -u
NB=${NB:-16}; STAGES=${STAGES:-4096}; WIDTH=32; JOBS=${JOBS:-4}
# Debian 包里 verilator_bin 在 /usr/bin，hierarchical 子进程默认去
# /usr/share/verilator 下找，容器内补一个符号链接
ln -sf /usr/bin/verilator_bin /usr/share/verilator/verilator_bin 2>/dev/null || true
mkdir -p rtl sim
echo "== toolchain =="
verilator --version
verilator --help | grep -- '--hierarchical'
echo "nproc=$(nproc)"
python3 gen.py "$NB" "$STAGES" "$WIDTH"
SRC="rtl/top.v rtl/bigblock.v sim/tb.cpp"
COMMON="--unroll-count 65536 --cc --exe --top-module top"

run_mode () {
  local mode=$1; local extra=$2; local cfg=$3
  echo
  echo "================ MODE: $mode (extra='$extra' cfg='$cfg') ================"
  rm -rf obj_dir Vtop_$mode
  echo "--- stage 1: verilator (generate C++ / hier makefiles) ---"
  { time verilator $COMMON $extra $cfg $SRC ; } 2>&1
  echo "--- stage 2: make -j$JOBS (block verilation if hier + g++ + link) ---"
  { time make -C obj_dir -f Vtop.mk -j"$JOBS" ; } 2>&1 \
    | grep -E "/usr/bin/verilator -f|Archive|Error|real|user|sys"
  cp obj_dir/Vtop Vtop_$mode
  echo "--- run model ---"
  ./Vtop_$mode
  echo "--- generated C++ lines under obj_dir ---"
  find obj_dir -name "*.cpp" -exec cat {} + | wc -l
  echo "--- archives (block libs) ---"
  find obj_dir -name "*.a" | sort
  echo "--- incremental: touch top.v (block internals unchanged) ---"
  touch rtl/top.v
  { time make -C obj_dir -f Vtop.mk -j"$JOBS" ; } 2>&1 | grep -E "/usr/bin/verilator -f|Archive|Error|real|user|sys"
  echo "--- incremental: touch bigblock.v (block source changed) ---"
  touch rtl/bigblock.v
  { time make -C obj_dir -f Vtop.mk -j"$JOBS" ; } 2>&1 | grep -E "/usr/bin/verilator -f|Archive|Error|real|user|sys"
  echo "--- top-level layout ---"
  find obj_dir -maxdepth 1 | sort
}

run_mode flat         ""               ""
run_mode hierarchical "--hierarchical" "blocks.vlt"
echo
echo "benchmark done: NB=$NB STAGES=$STAGES WIDTH=$WIDTH JOBS=$JOBS"
