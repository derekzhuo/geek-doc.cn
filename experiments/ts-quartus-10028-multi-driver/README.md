# ts-quartus-10028-multi-driver

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-10028-multi-driver.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译复现
`Error (10028): Can't resolve multiple constant drivers for net "led"`
的对照实验：同一份带 `force_off` 强制熄灭输入的闪烁计数器，问题版本把覆盖逻辑写进
第二个 `always` 块，让寄存器 `led` 同时被两个时序进程驱动；Quartus 综合阶段报 10028，
并伴随 `Error (10029): Constant driver at md_bad.v(18)` 指出另一个驱动点，再连锁
`Error (12153): Can't elaborate top-level user hierarchy`，全编译失败。修复版本把
`force_off` 分支合并进拥有 `led` 的唯一 `always` 块（复位之外按优先级判断），一个寄存器
只剩一个驱动，同一套 `quartus_sh` Tcl 流程全编译 0 error 收官。

## 文件

- `md_bad.v` —— 问题版本：两个 `always` 块都对 `led` 赋值，第 28 行触发 10028、
  第 18 行被 10029 标为另一处常量驱动
- `md_good.v` —— 修复版本：覆盖逻辑合并进唯一 `always`，`force_off` 优先于计数翻转，
  全编译 0 error / 12 warning
- `flow_bad.tcl` / `flow_good.tcl` —— `quartus_sh` 编译脚本：建工程、登记源文件、
  显式指定 `TOP_LEVEL_ENTITY md_top`（工程名与模块名不同名时必须显式指定，否则报
  `Error (12007) Top-level design entity ... is undefined`）、`execute_flow -compile`
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 bad/good 选择流程并落日志
- `err-10028-multi-driver.log` —— 真实报错日志：10028（md_bad.v:28）+ 10029（md_bad.v:18）
  + 12153 层次展开失败 + 293001 全编译失败（5 errors）
- `fix-compile-pass.log` —— 修复后真实全编译日志：综合、布局布线、Assembler、
  Timing Analyzer 四阶段全过，`Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 问题版本：quartus_sh 非零退出，日志中出现 Error (10028)
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad

# 修复版本：quartus_sh 退出码 0，日志含 Full Compilation was successful
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow good
```

也可以直接调用 Quartus Shell：

```bat
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_bad.tcl
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_good.tcl
```

## 读数要点

- 10028 指向的行是「无法裁决的赋值点」，10029 负责给出另一个驱动源；两条要连起来读，
  修复目标是让同一个 `reg` 在所有时刻只存在一个驱动进程，而不是只删 10028 指向的那一行。
- Verilog 语义里多个 `always` 对同一寄存器赋值属于多驱动，不是「后写覆盖先写」；
  需要条件优先级时，在唯一 `always` 内用 `if / else if` 表达（本实验的 `force_off`
  优先于 `cnt == 0` 翻转）。
- 12153 是 10028/10029 的下游连锁：顶层层次无法展开，后续 Fitter 阶段不会启动；
  修掉根因后它会自行消失，不需要单独处理。
- 修复版日志里 12 个 warning 全部是无引脚约束（169085）与无 SDC（332012）类提示，
  不阻断编译；无 SDC 时 Timing Analyzer 自动派生 1GHz 虚拟时钟，会出现
  `Timing requirements not met` 的 Critical Warning——这是约束缺失的假收敛信号，
  与真实时序违例的区分在后续 SDC 实验中展开。
- 两次编译都出现 `Info (125061): Changed top-level design entity name to "md_top"`，
  证明 Tcl 中的 `TOP_LEVEL_ENTITY` 显式指派生效。
