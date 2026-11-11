# ts-vivado-synth-8-3352-multi-driven-net

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-3352-multi-driven-net.html>

Vivado 综合 `CRITICAL WARNING: [Synth 8-3352] multi-driven net` 复现与修复实验：
同一条 `wire y` 同时被一条连续赋值和一个子模块实例输出驱动，综合器在 `y_OBUF`
上报双驱动；修复方式是让实例输出落到内部线网，再由唯一一条连续赋值按条件选择。

## 文件

- `net_bad.v` —— 问题顶层：`assign y = a & b` 与 `and_sub` 实例的 `.y(y)` 同时驱动 `y`
- `net_fixed.v` —— 修复顶层：实例输出接内部 `sub_y`，`assign y = sel ? sub_y : (a & b)` 单驱动
- `and_sub.v` —— 两输入与门子模块，两个顶层共用
- `v7_err.tcl` / `v7_fix.tcl` —— 综合脚本，`read_verilog` 后 `synth_design -part xc7a35tcpg236-1`
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-synth-8-3352.log` / `fix-synth-pass.log` —— 真实综合日志：报错版（2 条 8-3352 critical warning）与修复版（0 error / 0 critical warning）各一份

## 复现报错（Windows，Vivado 2017.4）

```bat
rem 问题版本：y_OBUF 双驱动，报两条 Synth 8-3352
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v7_err.tcl

rem 修复版本：单驱动，综合 0 error / 0 critical warning
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v7_fix.tcl
```

也可用包装器执行：`powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl v7_err.tcl -Log err.log`。
器件型号可按手头板子替换 `-part` 参数，双驱动报错与具体器件无关。
