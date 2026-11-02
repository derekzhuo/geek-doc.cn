#!/usr/bin/env bash
# Local replay of the two CI gates (lint -> sim).
# - If verilator is on PATH, run natively (needs g++/make as well).
# - Otherwise set VERILATOR_IMG to a Verilator docker image, e.g.
#       VERILATOR_IMG=geek-eda:0.3-sta ./run.sh
set -u

TOP="counter"
RTL="rtl/${TOP}.v"
TB="sim/tb_${TOP}.cpp"
mkdir -p build

if command -v verilator >/dev/null 2>&1; then
    vl() { verilator "$@"; }
    runbin() { "./obj_dir/V${TOP}"; }
else
    IMG="${VERILATOR_IMG:?set VERILATOR_IMG to a Verilator docker image, or install verilator locally}"
    vl() { docker run --rm -v "$PWD":/work -w /work "$IMG" verilator "$@"; }
    runbin() { docker run --rm -v "$PWD":/work -w /work "$IMG" "./obj_dir/V${TOP}"; }
fi

echo "== [gate 1/2] lint: verilator --lint-only -Wall =="
if ! vl --lint-only -Wall --top-module "$TOP" "$RTL"; then
    echo "lint gate FAILED -> sim gate skipped"
    exit 1
fi
echo "lint gate OK (rc=0)"

echo "== [gate 2/2] sim: verilator --cc --exe --build, then run =="
if command -v verilator >/dev/null 2>&1; then
    if ! verilator --cc --exe --build --top-module "$TOP" "$RTL" "$TB" >build/compile.log 2>&1; then
        echo "sim gate FAILED to build, last lines of build/compile.log:"
        tail -n 5 build/compile.log | sed 's/^/  | /'
        exit 1
    fi
else
    if ! docker run --rm -v "$PWD":/work -w /work "$IMG" sh -c \
        "verilator --cc --exe --build --top-module ${TOP} ${RTL} ${TB} >build/compile.log 2>&1"; then
        echo "sim gate FAILED to build, last lines of build/compile.log:"
        tail -n 5 build/compile.log | sed 's/^/  | /'
        exit 1
    fi
fi
runbin
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "sim gate FAILED (rc=$rc)"
    exit 1
fi
echo "sim gate OK (rc=0)"
echo "ALL GATES PASS"
