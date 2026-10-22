#!/usr/bin/env bash
# 复现「abc 找不到单元库」：-liberty 指向不存在的路径；有 sky130A PDK 时追加修复项
set -u
cd "$(dirname "$0")"
mkdir -p logs

run_log() {
  local name="$1"; shift
  {
    echo "# command: $*"
    echo "# date: $(date +%FT%T%z)"
    echo "# host-toolchain: $(yosys -V 2>/dev/null | head -1)"
    echo "---"
    "$@"
    rc=$?
    echo "---"
    echo "# exit_code: $rc"
  } > "logs/$name.log" 2>&1
}

# 触发：abc -liberty 指到不存在的库文件
run_log err-bad-libdir \
  yosys -Q -T -p "read_verilog src/counter8.v; synth -top counter8; abc -liberty /nonexistent/lib/sky130_fd_sc_hd.lib"

# 修复：探测本机 sky130A liberty（volare / open_pdks 常见位置）
SKY130_LIB=$(ls "$HOME"/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib \
  /usr/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib 2>/dev/null | head -1)
if [ -n "$SKY130_LIB" ]; then
  run_log fix-real-liberty \
    yosys -Q -T -p "read_verilog src/counter8.v; synth -top counter8; abc -liberty $SKY130_LIB; stat"
else
  echo "sky130 liberty not found; skipped fix-real-liberty (install sky130A PDK to enable)" \
    > logs/fix-real-liberty.log
fi

echo "== logs =="; wc -l logs/*.log
