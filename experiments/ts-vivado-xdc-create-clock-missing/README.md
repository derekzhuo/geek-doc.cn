# ts-vivado-xdc-create-clock-missing

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-xdc-create-clock-missing.html>（上线后生效）

Vivado XDC 时钟约束目标不存在的对照实验：`create_clock` 引用了设计里不存在的
端口 `clkk`（真实端口名是 `clk`）。综合本身不会硬失败，但约束被静默跳过，
最终 `report_clocks` 报告设计里一个时钟都没有——时序约束在无声中失效。
把端口名改对后，同一份流程在时钟报告里得到周期 10 ns 的 `sys_clk`。

## 文件

- `clock_gate.v` —— 带使能的 4 位计数器，时钟端口名为 `clk`
- `clocks_bad.xdc` —— 问题约束：`create_clock ... [get_ports clkk]`，目标端口不存在
- `clocks_ok.xdc` —— 正确约束：`[get_ports clk]`
- `v20_err.tcl` / `v20_fix.tcl` —— 非工程模式综合脚本，末尾 `report_clocks` 验证时钟是否建成
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-xdc-clock.log` —— 真实报错日志：12-584 + CRITICAL WARNING 12-4739，report_clocks 再报 12-3502 无时钟
- `fix-synth-pass.log` —— 修复后真实综合日志：sys_clk 10.000 ns，源端口 clk

## 复现（Windows，Vivado 2017.4）

```bat
rem 问题版本：综合不中断，但时钟约束静默失效
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v20_err.tcl

rem 修复版本：report_clocks 输出 sys_clk 10.000 ns
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v20_fix.tcl
```

真机日志里坏版本的关键签名：`WARNING: [Vivado 12-584] No ports matched 'clkk'`
紧接 `CRITICAL WARNING: [Vivado 12-4739] create_clock:No valid object(s) found`，
综合收尾行仍是 0 errors，因此只看退出码会漏掉这条约束事故，必须以
`report_clocks` 的 12-3502「Design has no clocks defined」作为兜底判据。
