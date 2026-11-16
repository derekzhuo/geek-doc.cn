# ts-vivado-xdc-generated-clock-missing

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-generated-clock-missing.html>（上线后生效）

FF 二分频时钟域漏约束 `create_generated_clock` 的对照实验。设计里
`clk_div_reg` 把 10 ns 输入时钟二分频，下游寄存器 `q_reg` 由 `clk_div`
驱动。

- **漏约束版**：XDC 只在输入端口 `clk` 上建 `sys_clk`，没有派生时钟定义。
  `report_clocks` 的 Generated Clocks 段为空，`q_reg` 的时序路径在整份
  timing summary 里完全不出现（日志中 `q_reg` 出现 0 次）——这个时钟域
  处于未约束状态，工具不会检查它的建立/保持时间，却不会给任何硬错误。
- **修复版**：补一行
  `create_generated_clock -name clk_div -source [get_ports clk] -divide_by 2 [get_pins clk_div_reg/Q]`，
  时钟报告出现 20.000 ns 的 `clk_div`（属性 P,G），`q_reg` 路径进入
  Intra/Inter Clock 表（日志中 `q_reg` 出现 5 次），跨时钟域
  `clk_div → sys_clk` 在交互报告中可查，零 CRITICAL WARNING。

## 文件

- `clock_div.v` —— 二分频寄存器 + 由分频时钟驱动的下游寄存器
- `clocks_bad.xdc` —— 只有主时钟，漏派生时钟约束
- `clocks_ok.xdc` —— 补 `create_generated_clock ... -divide_by 2`
- `x13_err.tcl` / `x13_fix.tcl` —— 非工程模式综合，依次 report_clocks / report_clock_interaction / report_timing_summary
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-missing-genclk.log` —— 真实日志：Generated Clocks 段为空，q_reg 零次出现
- `fix-genclk.log` —— 真实日志：clk_div 20.000 ns 建成，q_reg 路径受时序分析覆盖

## 复现（Windows，Vivado 2017.4）

```bat
rem 漏约束：时序报告对 clk_div 域视而不见
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x13_err.tcl

rem 补派生时钟：clk_div 进时钟表，下游路径受约束
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x13_fix.tcl
```

排查要点：① 触发器搭出来的分频时钟不会被自动约束（MMCM/PLL 输出才会
自动派生时钟对象），必须手写 `create_generated_clock`；② 漏约束不报错，
判据是 `report_clocks` 的 Generated Clocks 段和时序摘要里的路径覆盖——
该出现的寄存器（本例 `q_reg`）在报告里查无此路径，就是漏网时钟域；
③ 派生时钟的 `-source` 指向主时钟传播经过的引脚或端口，周期按分频比
推导，修复后用交互报告确认跨域关系符合预期。
