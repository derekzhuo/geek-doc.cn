# ts-vivado-xdc-clock-groups-async

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-clock-groups-async.html>（上线后生效）

`set_clock_groups -asynchronous` 对真实跨时钟域路径的影响对照实验。设计中 `stage_reg` 位于 10 ns 的 `clk_a` 时钟域，`q_reg` 位于 7 ns 的 `clk_b` 时钟域，二者之间存在一条没有同步器保护的跨时钟域数据路径。

- **基线版**：只创建 `clk_a` 和 `clk_b`。`report_clock_interaction` 将 `clk_a → clk_b` 标为 `Timed (unsafe)`；显式 `report_timing` 显示 `Slack (VIOLATED): -0.383ns`，路径组为 `clk_b`，时序摘要中 Setup/Hold 各有 1 个失败端点。
- **异步时钟组版**：增加 `set_clock_groups -asynchronous -group [get_clocks clk_a] -group [get_clocks clk_b]`。时钟交互矩阵对应单元变为 `Ignored / Asynchronous Groups`；显式报告仍列出这条物理路径，但显示 `Timing Exception: Asynchronous Clock Groups`、`Slack: inf`、`Path Group: (none)`，时序摘要中的 Setup/Hold Failing Endpoints 变为 `NA`。

## 文件

- `async_clock_groups.v` —— 两级寄存器分属两个时钟域的最小设计
- `baseline.xdc` —— 只创建两个时钟
- `async_groups.xdc` —— 增加异步时钟组约束
- `baseline.tcl` / `async_groups.tcl` —— 非工程模式综合与时钟交互、时序报告
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `baseline-crossing.log` / `async-groups-cut.log` —— Vivado 2017.4 真实输出

## 复现（Windows，Vivado 2017.4）

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source baseline.tcl
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source async_groups.tcl
```

`set_clock_groups` 的作用是切断两个时钟组之间的常规时序检查，不是把跨时钟域数据路径自动变成安全电路。报告中的 `Asynchronous Clock Groups` 例外只说明工具不再按普通同步路径收敛；设计仍需根据协议加入双触发器同步器、异步 FIFO 或握手等真正的跨时钟域处理。
