#!/usr/bin/env bash
set -u

bad_compile=1
bad_run=1
fixed_compile=1
fixed_run=1

echo "=== implicit signed port ==="
echo "$ iverilog -g2012 -s tb -o bad_simv bad.sv"
iverilog -g2012 -s tb -o bad_simv bad.sv 2>&1
bad_compile=$?
echo "bad compile exit=$bad_compile"
if [ "$bad_compile" -eq 0 ]; then
    echo "$ vvp bad_simv"
    vvp bad_simv 2>&1
    bad_run=$?
    echo "bad run exit=$bad_run"
fi

echo "=== explicit signed cast ==="
echo "$ iverilog -g2012 -s tb -o fixed_simv fixed.sv"
iverilog -g2012 -s tb -o fixed_simv fixed.sv 2>&1
fixed_compile=$?
echo "fixed compile exit=$fixed_compile"
if [ "$fixed_compile" -eq 0 ]; then
    echo "$ vvp fixed_simv"
    vvp fixed_simv 2>&1
    fixed_run=$?
    echo "fixed run exit=$fixed_run"
fi

if [ "$bad_compile" -eq 0 ] && [ "$bad_run" -eq 0 ] && \
   [ "$fixed_compile" -eq 0 ] && [ "$fixed_run" -eq 0 ]; then
    echo "PASS: implicit result observed and explicit signed conversion verified"
    exit 0
fi

echo "FAIL: compile or simulation returned nonzero"
exit 1
