# ts-cocotb-TimeoutError-drive-read：cocotb with_timeout 超时复现实验

**对应教程**：https://geek-doc.cn/eda/ts-cocotb-TimeoutError-drive-read.html

## 复现

```sh
make run MODULE=test_async_fifo_timeout
```

`testbench/test_async_fifo_timeout.py` 里有两个对照用例：

- `wait_edge_never_comes`（挂死版）：忘记 `Clock(dut.wclk, ...).start()`，`with_timeout(RisingEdge(dut.wclk), 500, "ns")` 在 500ns 抛 `SimTimeoutError`；
- `wait_edge_fixed`（修复版）：先起时钟，同一个等待立即通过。

回归汇总应为 `TESTS=2 PASS=1 FAIL=1`——FAIL 的那个就是本实验要演示的报错。

## 文件

- `rtl/async_fifo.v`：最小异步 FIFO DUT（只要有 `wclk` 口即可，功能从简）；
- `testbench/test_async_fifo_timeout.py`：挂死版/修复版两个 test；
- `Makefile`：cocotb 标准 Makefile.sim 封装。

环境：cocotb ≥1.8 + Icarus Verilog ≥11（实测 cocotb 1.8.1 + Icarus 11.0）。
