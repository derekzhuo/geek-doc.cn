# ts-vivado-synth-8-327-case-latch

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-327-case-latch.html>

Vivado 综合 `WARNING: [Synth 8-327] inferring latch` 复现与修复实验：组合逻辑
`always @(*)` 里的 `case` 没有覆盖全部 `sel` 取值、也没有 `default`，未覆盖分支下
`y` 必须保持原值，综合器据此推断出锁存器；补上 `default` 分支后每条路径都给 `y`
赋值，设计回到纯组合逻辑，8-327 警告消失。

## 文件

- `latch_case_bad.v` —— 问题版本：`case` 只覆盖 `2'b00/2'b01`，`sel=10/11` 时 `y` 保持，推断锁存器
- `latch_case_fixed.v` —— 修复版本：加 `default: y = 1'b0`，所有分支均赋值，无锁存器
- `v8_err.tcl` / `v8_fix.tcl` —— 综合脚本，`synth_design` 后接 `report_utilization` 可核对锁存器数量
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-synth-8-327.log` / `fix-synth-pass.log` —— 真实综合日志：报错版（Synth 8-155 非完整 case + Synth 8-327 锁存器）与修复版（0 warning）各一份

## 复现报错（Windows，Vivado 2017.4）

```bat
rem 问题版本：先报 Synth 8-155 case 不完整，再报 Synth 8-327 推断锁存器
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v8_err.tcl

rem 修复版本：补 default 后综合 0 error / 0 critical warning / 0 warning
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v8_fix.tcl
```

也可用包装器执行：`powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl v8_err.tcl -Log err.log`。
日志中的 `report_utilization` 段落可直接对比修复前后的 Slice LUT 占用变化。
