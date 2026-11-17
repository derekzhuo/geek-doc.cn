# ts-quartus-10170-syntax

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-10170-syntax.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译复现 `Error (10170): Verilog HDL syntax error ... near text`
的对照实验：同一份闪烁计数器设计，问题版本在 `reg [23:0] cnt` 声明处漏写行尾分号，
解析器在下一个关键字 `always` 处无法继续，报 10170 并连带 `Error (10112) Ignored design
unit`，整个设计单元被跳过、全编译失败；补回分号后同一套 `quartus_sh` Tcl 流程全编译
0 error 收官。实验展示「报错 token 在后、真正出错位置在上一行末尾」这一 HDL 解析类
报错的通用定位规律。

## 文件

- `led_bad.v` —— 问题版本：`reg [23:0] cnt` 漏分号，第 11 行 `always` 处触发 10170
- `led_good.v` —— 修复版本：补回分号，全编译 0 error / 12 warning
- `flow_bad.tcl` / `flow_good.tcl` —— `quartus_sh` 编译脚本：建工程、登记源文件、
  显式指定 `TOP_LEVEL_ENTITY led_blink`（工程名与模块名不同名时必须显式指定，否则报
  `Error (12007) Top-level design entity ... is undefined`）、`execute_flow -compile`
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 bad/good 选择流程并落日志
- `err-10170-syntax.log` —— 真实报错日志：10170（led_bad.v:11 near text "always"）
  + 10112 设计单元忽略 + 293001 全编译失败
- `fix-compile-pass.log` —— 修复后真实全编译日志：综合、布局布线、Assembler、
  Timing Analyzer 四阶段全过，`Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 问题版本：quartus_sh 非零退出，日志中出现 Error (10170)
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

- 10170 的 `near text: "always"` 是解析崩溃点，不是错误本身；定位时从该位置向上回看
  一到两行，优先检查行尾分号、`end`/`endmodule` 配对与括号闭合。
- 修复版日志里 12 个 warning 全部是无引脚约束（169085）与无 SDC（332012）类提示，
  不阻断编译；无 SDC 时 Timing Analyzer 自动派生 1GHz 虚拟时钟，会出现
  `Timing requirements not met` 的 Critical Warning——这是约束缺失的假收敛信号，
  与真实时序违例的区分在后续 SDC 实验中展开。
- 两次编译都出现 `Info (125061): Changed top-level design entity name to "led_blink"`，
  证明 Tcl 中的 `TOP_LEVEL_ENTITY` 显式指派生效。
