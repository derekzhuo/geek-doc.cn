#!/usr/bin/env bash
# 一次跑通：Verilator 5.020 容器内分别导出 VCD 与 FST，并做体积/文件头对照
set -u
cd "$(dirname "$0")"
IMAGE=geek-eda:0.3-sta
DK="docker run --rm -v $PWD:/work -w /work $IMAGE"

echo "# command: bash run.sh"
echo "# date: 2026-11-03"
echo "# host-toolchain: Verilator 5.020 (geek-eda:0.3-sta docker)"

echo "== tool versions =="
$DK verilator --version
$DK bash -c 'gtkwave --version 2>&1 | head -1; which fst2vcd vcd2fst xvfb-run'

echo "== build VCD variant (--trace) =="
$DK verilator --cc --exe --build -Wall --top-module counter \
    --Mdir obj_vcd --trace counter.v tb_main.cpp
$DK ./obj_vcd/Vcounter

echo "== build FST variant (--trace-fst) =="
$DK verilator --cc --exe --build -Wall --top-module counter \
    --Mdir obj_fst --trace-fst counter.v tb_main.cpp
$DK ./obj_fst/Vcounter

echo "== file sizes =="
ls -l wave.vcd wave.fst
$DK bash -c "stat -c '%n %s bytes' wave.vcd wave.fst; echo -n 'VCD timestamps: '; grep -c '^#' wave.vcd; echo -n 'size ratio vcd/fst: '; echo \$(( \$(stat -c %s wave.vcd) / \$(stat -c %s wave.fst) ))"

echo "== file types and FST header =="
file wave.vcd wave.fst
xxd wave.fst | head -3

echo "== VCD head =="
head -20 wave.vcd
echo "== VCD tail =="
tail -5 wave.vcd

echo "== fst2vcd text verification (head) =="
$DK fst2vcd wave.fst 2>/dev/null | head -20

echo "== xvfb-run gtkwave command-line probe =="
$DK bash -c 'xvfb-run -a gtkwave --version 2>&1 | head -2' || true

echo "== done =="
