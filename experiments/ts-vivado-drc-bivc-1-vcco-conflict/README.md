# ts-vivado-drc-bivc-1-vcco-conflict

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-drc-bivc-1-vcco-conflict.html>（上线后生效）

同一 I/O bank 内混用不同 VCCO 电平标准的对照实验。实验器件为 `xc7a35tcpg236-1`，先用 Tcl 查询封装引脚所属 bank，确认 `V17`、`V16`、`U16` 都在 bank 14，`W5` 在 bank 34。

- **bank 探针**：`probe_banks_v2.tcl` 通过 `get_iobanks -of_objects` 和 `BANK` 属性两种方式查询引脚，日志中可看到 `V17`、`V16` 均属于 bank 14。
- **冲突版**：bank 14 内的 `a` 约束为 `LVCMOS33`（要求 VCCO=3.300V），`b` 约束为 `LVCMOS18`（要求 VCCO=1.800V）。`place_design` 前的 DRC 报 **`ERROR: [DRC BIVC-1] Bank IO standard Vcc: Conflicting Vcc voltages in bank 14`**，随后出现 `Vivado_Tcl 4-23` 和 `Common 17-39`，布局器不启动。
- **修复版**：将 bank 14 内端口统一为 `LVCMOS33`，重新综合、优化和布局，错误清零，`place_design` 正常完成。

## 文件

- `bank_probe.v` —— 三输入一输出的最小时序逻辑
- `probe_banks_v2.tcl` —— 查询封装引脚与 I/O bank 映射
- `bad.xdc` —— bank 14 内混用 LVCMOS33 与 LVCMOS18
- `fixed.xdc` —— bank 14 内统一 LVCMOS33
- `bad.tcl` / `fixed.tcl` —— 非工程模式综合、优化和布局脚本
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `bank-probe-v2.log` / `bad-iostandard-conflict.log` / `fixed-iostandard-aligned.log` —— Vivado 2017.4 真实输出

## 复现（Windows，Vivado 2017.4）

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source probe_banks_v2.tcl
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source bad.tcl
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source fixed.tcl
```

排查这类问题时先确认引脚所在 bank，再检查同一 bank 内所有端口的 `IOSTANDARD` 是否推导出同一种 VCCO。不要只为了让 DRC 通过而把约束改成与电路板供电不一致的电平；约束应描述板上真实供电，电压不同的外设要分配到独立 bank。
