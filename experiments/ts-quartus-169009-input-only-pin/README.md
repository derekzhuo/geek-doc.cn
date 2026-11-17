# ts-quartus-169009-input-only-pin

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-169009-input-only-pin.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译复现 Fitter 放置硬错误
`Error (169009): Cannot place output or bidirectional pin led in input pin location 25`
的对照实验。EP4CE6E22C8（EQFP144）的 PIN_25 是输入专用脚，不能承载输出方向的端口；同一份
单 LED 闪烁设计（`pd_top`，clk/rst_n/led 三端口），问题流程把输出 `led` 约束到 PIN_25，
Analysis & Synthesis 正常通过（综合只看 RTL，不挑封装脚位），到 Fitter 阶段才被拒绝，
连锁 `Error (171000): Can't fit design in device` 与 293001 全编译失败（4 errors）；
把 `led` 改到通用 IO 脚 PIN_87（clk/rst_n 仍为 PIN_23/24）后同一套 `quartus_sh`
Tcl 流程全编译 0 error 收官。这个案例也出现在本站 Quartus 入门教程的首次踩坑记录里，
本实验把它补成可独立复现、带规范化日志的对照包。

## 文件

- `pin_dir.v` —— 两个流程共用的唯一设计：24 位计数器翻转单路 LED，模块 `pd_top`
- `flow_bad.tcl` —— 问题流程：led→PIN_25（输入专用脚），预期 Fitter 169009 + 171000
- `flow_good.tcl` —— 修复流程：led→PIN_87（通用 IO，Q4 实验已由 Fitter 验证可放输出），
  其余约束不变，预期全编译 0 error
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 bad/good 选择流程并落日志
- `err-169009-input-only-pin.log` —— 真实报错日志（精简规范化版）：综合 0 error 通过、
  Fitter 169009（pin_dir.v:7）+ 171000 + 293001（4 errors, 5 warnings）+ 23031
- `fix-compile-pass.log` —— 修复后真实全编译日志（全量 209 行）：
  `Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 问题流程：quartus_sh 非零退出，Fitter 阶段出现 Error (169009)
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad

# 修复流程：quartus_sh退出码 0，日志含 Full Compilation was successful
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow good
```

也可以直接调用 Quartus Shell：

```bat
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_bad.tcl
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_good.tcl
```

## 读数要点

- 169009 是 **Fitter 阶段**错误，不是综合错误：RTL 本身合法，综合照样 0 error 收官；
  定位这类问题先看报错属于哪个阶段，综合通过不代表约束可实现。
- 报错原文自带两个定位要素——端口方向（output or bidirectional pin）与冲突脚位
  （input pin location 25），对照器件封装手册确认脚位能力即可，不需要怀疑 RTL。
- 171000（Can't fit design in device）是 169009 的下游连锁，不是芯片容量不够；
  根因消除后它自行消失，看到 171000 先向上翻第一条 Error。
- 同样是「管脚相关问题」，未分配引脚只触发 169085 Critical Warning 且编译成功
  （见姊妹实验 ts-quartus-169085-pin-unassigned），而方向冲突是硬错误——
  区别在于 Fitter 能否在合法脚位内完成放置。
- 两次编译都出现 `Info (125061): Changed top-level design entity name to "pd_top"`，
  证明 Tcl 中的 `TOP_LEVEL_ENTITY` 显式指派生效。
