#!/usr/bin/env bash
# 在 geek-eda:0.4-flow 容器内激活 cocotb 虚拟环境后执行
set -e
source /opt/venvs/cocotb/bin/activate
echo "## cocotb $(python -c 'import cocotb; print(cocotb.__version__)')"
echo "## $(iverilog -V 2>/dev/null | head -1)"
echo "## python $(python --version 2>&1)"
make clean >/dev/null 2>&1 || true
make SIM=icarus
