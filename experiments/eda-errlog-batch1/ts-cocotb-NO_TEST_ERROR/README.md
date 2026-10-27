# ts-cocotb-NO_TEST_ERROR

复现 cocotb `NO_TEST_ERROR` / `CRITICAL ... Failed to import module ... 0 tests`：
`MODULE` 名字和 testbench 文件名对不上时，仿真启动但收集不到任何测试。

## 目录

- `lab/rtl/async_fifo.v`：双时钟异步 FIFO（深度 16，格雷码指针 + 两级同步）。
- `lab/testbench/test_async_fifo.py`：两个测试 `single_write_read`、
  `random_back_to_back`（200 个随机令牌跨时钟保序）。
- `lab/Makefile`：cocotb 标准 Makefile，`TOPLEVEL=async_fifo`、`MODULE=test_async_fifo`。
- `run.sh`：跑错误/修复两种 MODULE，日志落 `logs/`。

## 复现

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install cocotb
bash run.sh
```

- `logs/err-wrong-MODULE.log`：`make MODULE=nonexistent_tb` → CRITICAL，0 测试。
- `logs/fix-correct-MODULE.log`：`make` → TESTS=2 PASS=2 FAIL=0。

## 重建与复跑说明

原始 lab 在 eda-golden v1 镜像（Ubuntu 22.04 + cocotb 1.8.1 + Icarus 11）内、未随镜像入库；
本工程按原始证据日志（TOPLEVEL/MODULE、两个测试名、200 令牌保序断言信息）重建，
2026-10-22 在 macOS + Icarus 13.0 + cocotb 2.1 本地复跑通过（TESTS=2 PASS=2）。
RTL 的 full/empty 直接用当前格雷指针比较（不用 next 指针反馈门控），语义等价且
避免 iverilog 对该组合环的迭代退化，注释里有说明。

## 原始证据

本目录 `evidence/`（原始日志，与教程内嵌摘录同源）（2026-10-21，cocotb 1.8.1 / Icarus 11.0）
