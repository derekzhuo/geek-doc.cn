#!/usr/bin/env bash
# Verilator --timing 延时模型流程最小复现（镜像 geek-eda:0.3-sta）
set -u
cd "$(dirname "$0")"
IMG=geek-eda:0.3-sta
vrun() { docker run --rm -v "$PWD":/work -w /work "$IMG" "$@"; }

echo "===== verilator --version ====="
vrun verilator --version

echo "===== timing-related options (--help) ====="
vrun verilator --help | grep -iE 'timing|timescale'

echo "===== step1: --cc without timing flag on #delay RTL (expect NEEDTIMINGOPT) ====="
vrun verilator --cc --top-module tb tb.v inv.v
echo "exit_code=$? (nonzero expected)"

echo "===== step2: --binary --timing build and run ====="
vrun verilator --binary --timing tb.v inv.v
vrun ./obj_dir/Vtb

echo "===== step3: --no-timing (expect STMTDLY fatal) ====="
vrun verilator --binary --no-timing tb.v inv.v
echo "exit_code=$? (nonzero expected)"

echo "===== step4: event-control boundary probe under --timing ====="
vrun verilator --binary --timing event_probe.v
vrun ./obj_dir/Vevent_probe
