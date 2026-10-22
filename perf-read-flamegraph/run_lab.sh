# perf-read-flamegraph 一键复现脚本
# 用法: bash run_lab.sh
# 依赖: perf、gcc、perl，以及 Brendan Gregg 的 FlameGraph 工具集
#   git clone https://github.com/brendangregg/FlameGraph.git
# 可用 FG 环境变量指定 FlameGraph 路径: FG=/path/to/FlameGraph bash run_lab.sh
set -e
FG="${FG:-$HOME/FlameGraph}"
[ -x "$FG/flamegraph.pl" ] || { echo "请先克隆 FlameGraph 并用 FG=... 指定路径"; exit 1; }

CC="${CC:-gcc}"
CFLAGS="-O2 -g -fno-omit-frame-pointer -std=gnu99"
FREQ="${FREQ:-999}"

echo "== build =="
$CC $CFLAGS hotspot.c -o hotspot

echo "== sanity timing (7 次，取最小值看真实计算量) =="
for v in base opt; do
  echo "-- $v --"
  for i in 1 2 3 4 5 6 7; do /usr/bin/time -f "%e" ./hotspot "$v" 2>&1 >/dev/null; done
done

echo "== perf stat (软件事件；云主机硬件 PMU 可能 not supported) =="
for v in base opt; do
  echo "-- $v --"
  perf stat -e task-clock,context-switches,cpu-migrations,page-faults,minor-faults \
      ./hotspot "$v"
done

echo "== perf record (dwarf 回溯) =="
perf record -F "$FREQ" -g --call-graph dwarf,16384 -o perf_base.data -- ./hotspot base
perf record -F "$FREQ" -g --call-graph dwarf,16384 -o perf_opt.data  -- ./hotspot opt

echo "== perf report self / children =="
for v in base opt; do
  echo "---- $v self ----"
  perf report -i perf_$v.data --stdio --no-children -g none 2>/dev/null \
    | grep -E '^[[:space:]]+[0-9]+\.[0-9]+%' | head -12
  echo "---- $v children ----"
  perf report -i perf_$v.data --stdio --children -g none 2>/dev/null \
    | grep -E '^[[:space:]]+[0-9]+\.[0-9]+%' | head -10
done

echo "== perf annotate hash_djb2 =="
perf annotate -i perf_base.data --stdio --stdio-color never -s hash_djb2 2>/dev/null | head -45

echo "== folded + flamegraph svg =="
for v in base opt; do
  perf script -i perf_$v.data > out_$v.perf
  "$FG/stackcollapse-perf.pl" out_$v.perf > folded_$v.txt
  "$FG/flamegraph.pl" --title "hotspot ($v) CPU flame graph" --countname samples \
      folded_$v.txt > "images/flame_$v.svg"
done

echo "== differential flamegraph (后一个参数是基准 base) =="
"$FG/difffolded.pl" folded_opt.txt folded_base.txt > diff.txt
"$FG/flamegraph.pl" --title "opt vs base differential (red=regression, blue=improvement)" \
    --countname delta diff.txt > images/flame_diff.svg

echo "ALL_DONE : 浏览器打开 images/flame_base.svg / flame_opt.svg / flame_diff.svg"
