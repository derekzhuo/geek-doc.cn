# flow-cocotb-coroutines

**对应教程**：https://geek-doc.cn/eda/flow-cocotb-coroutines.html

cocotb 2.1 协程并发最小实验：一个两级流水延迟寄存器 `pipe_delay`，producer 与 watchdog 两个协程分别驱动与监测，对比四种汇合方式：

| 用例 | 写法 | 仿真耗时 | 监测结果 |
|---|---|---|---|
| `test_start_soon_then_join` | 两个 `start_soon` + `Join` | 92 ns | 抓到全部 4 拍 |
| `test_combine_waits_both` | `Combine(p_task, w_task)` | 102 ns | 抓到全部 4 拍 |
| `test_gather_modern_style` | `await gather(producer(...), watchdog(...))` | 102 ns | 抓到全部 4 拍（cocotb 2.1 推荐写法，无告警） |
| `test_sequential_await_misses_beats` | 顺序 `await` 两个协程 | 172 ns | 仅抓到残留 1 拍，漏 3 拍 |

`Join`/`Combine(Task)` 在 cocotb 2.1 仍可运行但会打 `DeprecationWarning`：推荐直接 `await task` 或用 `cocotb.triggers.gather`。

## 复现

需要 Docker 镜像 `geek-eda:0.4-flow`（cocotb 2.1.0 + Icarus Verilog 12.0）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow bash run.sh
```

预期末尾输出 `TESTS=4 PASS=4 FAIL=0 SKIP=0`。

## 文件

- `pipe_delay.v`：两级流水 DUT（SystemVerilog `for` 循环，编译带 `-g2012`）
- `test_pipe.py`：四条用例，producer/watchdog 两个协程
- `Makefile`：`SIM=icarus`，TOPLEVEL=pipe_delay
- `run.sh`：容器内激活 cocotb 虚拟环境并执行 `make SIM=icarus`
