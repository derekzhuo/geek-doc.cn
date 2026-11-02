#!/usr/bin/env bash
# 复现脚本：存量 FIFO 工程接入 verilator --lint-only
# 依赖：docker 镜像 geek-eda:0.3-sta（Verilator 5.020）；本机直装 verilator 时可把 vrun 改为直接调用
set -u
cd "$(dirname "$0")"
IMG=geek-eda:0.3-sta

vrun() {
    docker run --rm -v "$PWD":/work -w /work "$IMG" "$@"
}

echo "===== verilator --version ====="
vrun verilator --version

echo "===== lint legacy RTL (expect 2 warnings, exit 1) ====="
vrun verilator --lint-only -Wall --top-module fifo_top \
    rtl_bad/fifo_top.v rtl_bad/sync_fifo.v
echo "exit_code=$? (warning 在 lint-only 下默认致命，非零是预期)"

echo "===== same RTL with -Wno-fatal (exit 0) ====="
vrun verilator --lint-only -Wall -Wno-fatal --top-module fifo_top \
    rtl_bad/fifo_top.v rtl_bad/sync_fifo.v
echo "exit_code=$?"

echo "===== rerun lint on fixed RTL (expect clean, exit 0) ====="
vrun verilator --lint-only -Wall --top-module fifo_top \
    rtl_good/fifo_top.v rtl_good/sync_fifo.v
echo "fixed_exit_code=$?"
