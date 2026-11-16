# ts-vivado-xdc-multicycle-path

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-multicycle-path.html>（上线后生效）

`set_multicycle_path` 改变同一条寄存器路径时序要求的对照实验。设计是单
10 ns 时钟下的两级流水线，受测路径为 `stage_reg → q_reg`。

- **基线版**：XDC 只建时钟，`report_timing -from stage_reg -to q_reg`
  给出 `Requirement: 10.000ns`，即默认单周期建立要求。
- **多周期版**：加
  `set_multicycle_path 2 -setup -from [get_cells stage_reg] -to [get_cells q_reg]`，
  同一条路径的报告变为
  `Requirement: 20.000ns (sys_clk rise@20.000ns - sys_clk rise@0.000ns)`，
  捕获沿从第 1 个沿推迟到第 2 个沿，零 CRITICAL WARNING。

## 文件

- `mcp_path.v` —— 单时钟两级流水线，受测路径 stage_reg → q_reg
- `mcp_baseline.xdc` —— 只建 10 ns 时钟
- `mcp_set.xdc` —— 加 setup 多周期 2 的约束
- `x17_baseline.tcl` / `x17_mcp.tcl` —— 非工程模式综合后对同一路径 report_timing
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `baseline-timing.log` —— 真实日志：Requirement 10.000ns
- `mcp-timing.log` —— 真实日志：Requirement 20.000ns，捕获沿推迟到第 2 个时钟沿

## 复现（Windows，Vivado 2017.4）

```bat
rem 基线：默认单周期要求
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x17_baseline.tcl

rem 多周期：同一路径要求放宽到 20 ns
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x17_mcp.tcl
```

排查要点：① 多周期约束的效果要以 `report_timing` 里 Requirement 的实际
数值为准，约束没写错对象时报告会直接显示新的捕获沿；② `-from/-to` 用
`get_cells` 点名起止寄存器，对象匹配为空时约束静默失效（与其他 XDC
命令一样只给告警），改完必须重跑报告确认数值变化；③ 工程上放宽 setup
多周期通常要配套调整 hold 约束（`set_multicycle_path 1 -hold`），避免
保持检查沿错位，本篇证据只覆盖 setup 要求的变化，hold 配套写法在对应
教程中展开。
