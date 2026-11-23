# ts-quartus-169026-vccio-bank-conflict

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-169026-vccio-bank-conflict.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译复现 Fitter 同 bank VCCIO 不兼容硬错误
`Error (169026): Pin led_b with I/O standard assignment 3.0-V LVTTL is incompatible with I/O bank 5`
的对照实验。同一份双路 LED 设计（`ic_top`，clk/rst_n/led_a/led_b 四端口，led_a→PIN_87、
led_b→PIN_86，两脚同属 I/O bank 5），问题流程把 led_b 的 IO_STANDARD 指派为
`3.0-V LVTTL`，而同 bank 的 led_a 仍是 `3.3-V LVTTL`——3.0V 与 3.3V 两种 VCCIO
需求不能在同一个 bank 共存，Fitter 报 169026，并用一条 `Info (169073)` 点名同 bank
冲突脚 led_a 的 3.3V 需求（io_conflict.v:6），连锁 `Error (171000): Can't fit design
in device` 与 293001 全编译失败（4 errors, 5 warnings）；把四个端口统一为
`3.3-V LVTTL` 后同一套 `quartus_sh` Tcl 流程全编译 0 error 收官。

需要特别区分的另一种报错：`2.5-V/1.8-V/1.5-V/1.2-V LVTTL/LVCMOS` 等名称在
EP4CE6E22C8 上根本不在合法 I/O 标准词表内，会在更早的词表校验环节被
`Error (169216)` 拒绝，走不到 VCCIO 冲突判定；`3.0-V LVTTL/LVCMOS` 是该器件
接受的合法名称，因此才能真正触发同 bank VCCIO 冲突。169026 与 169216 是两个
不同阶段、不同根因的错误码，排查时先看错误码落在词表校验还是 bank 约束阶段。

## 文件

- `io_conflict.v` —— 两个流程共用的唯一设计：24 位计数器驱动双路 LED，模块 `ic_top`
- `flow_bad.tcl` —— 问题流程：led_b 指派 `3.0-V LVTTL`，与同 bank 3.3V 脚冲突，预期 Fitter 169026 + 171000
- `flow_good.tcl` —— 修复流程：四端口统一 `3.3-V LVTTL`，预期全编译 0 error
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 bad/good 选择流程并落日志
- `err-169026-vccio-conflict.log` —— 真实报错日志（规范化版，92 行）：
  169026 全文 + 169073 点名冲突脚 + 171000 + 293001（4 errors, 5 warnings）+ 23031
- `fix-compile-pass.log` —— 修复后真实全编译日志（212 行）：
  `Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 问题流程：quartus_sh 非零退出，Fitter 阶段出现 Error (169026)
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad

# 修复流程：quartus_sh 退出码 0，日志含 Full Compilation was successful
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow good
```

也可以直接调用 Quartus Shell：

```bat
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_bad.tcl
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_good.tcl
```

## 读数要点

- 169026 是 **Fitter 阶段**的 bank 约束错误：综合全程合法，问题在管脚约束表，
  不要回头改 RTL；修法只有两个方向——把不同 VCCIO 需求的输出/双向脚分到不同
  I/O bank，或把报错脚改成与本 bank 兼容的 I/O 标准。
- 169073 是定位冲突对方的关键 Info：它给出同 bank 里已占用另一档 VCCIO 的脚名
  与源文件行号，修约束时按这条信息找邻居脚，而不是只盯着 169026 点名的那一个。
- 171000（Can't fit design in device）是 169026 的下游连锁，不是芯片容量不够；
  根因消除后它自行消失，看到 171000 先向上翻第一条 Error。
- 注意与 169216 的阶段差异：I/O 标准名不在器件词表是 169216（名称合法性校验），
  名称合法但与同 bank 邻居的 VCCIO 不兼容才是 169026（bank 物理约束校验）。
- 管脚类四姊妹对照：未分配引脚只触发 169085 Critical Warning 且编译成功
  （ts-quartus-169085-pin-unassigned），输出脚放进输入专用脚是 169009 硬错误
  （ts-quartus-169009-input-only-pin），I/O 标准名不在器件词表是 169216 硬错误
  （ts-quartus-169216-invalid-io-standard），同一物理脚重复分配是 176310 硬错误
  （ts-quartus-176310-duplicate-pin-assignment），本篇是同 bank VCCIO 需求冲突的
  169026 硬错误。
