# ts-vivado-xdc-false-path-misuse

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-false-path-misuse.html>（上线后生效）

`set_false_path` 误用在真实同步路径上的对照实验。设计是同一个 10 ns 时钟下的两级流水线，受测路径为 `stage_reg → q_reg`，它每个时钟周期都在传递数据。

- **基线版**：只创建 `sys_clk`。`report_timing` 显示 `Slack (MET): 8.795ns`、`Requirement: 10.000ns`，路径组为 `sys_clk`，工具正常做建立/保持检查。
- **误加 false path 版**：对同一寄存器路径加 `set_false_path -from [get_cells stage_reg] -to [get_cells q_reg]`。显式 `report_timing` 仍会列出这条物理路径，但报告变成 `Slack: inf`、`Path Group: (none)`，并明确标出 `Timing Exception: False Path`；`report_timing_summary` 的 Setup/Hold Failing Endpoints 变为 `NA`，说明常规时序检查已不再约束它。

## 文件

- `false_path_design.v` —— 单时钟两级流水线
- `baseline.xdc` —— 只建 10 ns 时钟
- `false_path.xdc` —— 对真实同步路径误加 `set_false_path`
- `baseline.tcl` / `false_path.tcl` —— 非工程模式综合与 timing 报告
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `baseline-timing.log` / `false-path-cut.log` —— Vivado 2017.4 真实输出

## 复现（Windows，Vivado 2017.4）

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source baseline.tcl
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source false_path.tcl
```

排查时不要把“报告里还能看到路径”误认为约束没有生效。Vivado 的显式 `report_timing` 可以展示被豁免的路径，关键要看 `Timing Exception: False Path`、`Slack: inf`、`Path Group: (none)`，以及 timing summary 中该项检查是否变成 `NA`。同步数据路径只有在确实不需要时序保证时才能这样切断；普通流水线应保留默认检查或改用合适的多周期约束。
