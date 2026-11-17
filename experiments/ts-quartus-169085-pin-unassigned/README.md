# ts-quartus-169085-pin-unassigned

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-169085-pin-unassigned.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译对照实验，回答一个常见误解：**顶层引脚完全不分配，
Quartus 会不会直接报错？** 真机结论是不会——同一份六端口设计（clk、rst_n、led[3:0]）在零
引脚约束下全编译成功（0 error，退出码 0），只留下
`Critical Warning (169085): No exact pin location assignment(s) for 6 pins of 6 total pins`；
Fitter 自行决定管脚位置，并把 clk/rst_n 自动提升到全局时钟网络（PIN 23/24，
`Info (176353) Automatically promoted ...`）。补上完整 `set_location_assignment` 与
`IO_STANDARD "3.3-V LVTTL"` 约束后，169085 与 15714 同时消失，编译仍然 0 error。
未分配引脚是「能编过但上不了板」的告警态，和 176310（管脚无法放置）、20194（分配冲突）、
169029（电平标准冲突）这类真正阻断编译的硬错误不是一回事。

## 文件

- `pin_design.v` —— 两个流程共用的唯一设计：24 位计数器驱动四位 LED，模块 `pp_top` 六个端口
- `flow_warn.tcl` —— 零引脚约束流程：只登记源文件与 `TOP_LEVEL_ENTITY pp_top`，
  预期 169085 Critical Warning + 176353 自动提升 + 全编译成功
- `flow_fixed.tcl` —— 完整约束流程：clk→PIN_23、rst_n→PIN_24、led[0..3]→PIN_87/86/85/84，
  六脚全部 3.3-V LVTTL；预期 169085 计数为 0、全编译成功
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 warn/fixed 选择流程并落日志
- `warn-169085-unassigned.log` —— 零约束真实编译日志（精简规范化版）：
  169085（6/6 引脚无指派）、15714（I/O 指派不完整）、169124（5 个用户脚转为专用编程脚）、
  176353 全局时钟提升、未约束脚默认 2.5V VCCIO、`Full Compilation was successful. 0 errors, 12 warnings`
- `fixed-pin-assigned-pass.log` —— 完整约束真实全编译日志（全量 209 行）：
  169085 消失，169177/169178 确认 PIN 23/24 采用 3.3-V LVTTL，
  `Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 零约束：退出码 0，日志含 Critical Warning (169085) 但没有任何 Error
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow warn

# 完整约束：退出码 0，169085 消失，日志含 Full Compilation was successful
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow fixed
```

也可以直接调用 Quartus Shell：

```bat
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_warn.tcl
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_fixed.tcl
```

## 读数要点

- 169085 是 **Critical Warning 而不是 Error**：命令行流程退出码仍为 0，Assembler 照常生成
   sof；但 Fitter 替你随便选的脚位基本不可能对上板子原理图，所以这个状态只适合前期逻辑验证，
  上板前必须补齐约束。
- `Info (176353)` 的自动提升说明 Fitter 认出了时钟/复位的网络属性，即使你不约束也会把它们
  放进专用全局时钟路径（本设计落在 PIN 23 CLK1、PIN 24 CLK2）；显式约束后该行为保持不变。
- 零约束时未指定电平的管脚按 2.5V VCCIO 处理（日志 176211/176212），显式写 3.3-V LVTTL 后
  由 169178 逐脚确认；同 bank 混用不兼容电平才会触发 169029 硬错误，后续实验展开。
- 两个流程都有无 SDC 的 332012 Critical Warning，Timing Analyzer 自动派生 1GHz 虚拟时钟，
  属于约束缺失的假收敛信号，不阻断编译。
- 两次编译都出现 `Info (125061): Changed top-level design entity name to "pp_top"`，
  证明 Tcl 中的 `TOP_LEVEL_ENTITY` 显式指派生效。
