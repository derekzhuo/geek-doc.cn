# flow-cocotb-first-test

**对应教程**：https://geek-doc.cn/eda/flow-cocotb-first-test.html

cocotb 2.1.0 第一个测试流程的最小可运行工程：用 Python 写 testbench，经 VPI 驱动 Icarus Verilog 仿真中的一个 D 触发器。

## 文件

- `dff.v`：被测设计（DUT），带低电平异步复位的 D 触发器
- `test_dff.py`：cocotb 2.1 测试台，两条用例（复位保持、上升沿采样）
- `Makefile`：cocotb 标准接线（SIM / VERILOG_SOURCES / TOPLEVEL / COCOTB_TEST_MODULES）
- `run.sh`：一条命令复现实跑（含日志头与 results.xml 摘录）

## 复现

需要本机装有 geek-eda:0.3-sta 镜像（cocotb 2.1.0 + Icarus Verilog 12.0 + Python 3.12）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && make SIM=icarus'
```

预期末尾汇总行：`** TESTS=2 PASS=2 FAIL=0 SKIP=0 **`，并生成 `results.xml`（JUnit 格式）。

仿真产物 `sim_build/` 与 `results.xml` 为运行时生成物，不入库。
