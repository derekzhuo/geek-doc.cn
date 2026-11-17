# ts-quartus-169216-invalid-io-standard

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-169216-invalid-io-standard.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译复现 Fitter 管脚电平标准硬错误
`Error (169216): I/O standard assignment '...' to pin led_b is not supported by the device.
The name '...' is not a valid I/O standard name.`
的对照实验。器件固定为 Cyclone IV E EP4CE6E22C8（EQFP144），同一份双路 LED 设计
（`ic_top`，clk/rst_n/led_a/led_b 四端口，led_a 固定 PIN_87、led_b 固定 PIN_86），
只改 `led_b` 的 `IO_STANDARD` 指派，连续试三个名称——`2.5-V LVCMOS`、`1.8-V LVCMOS`、
`1.8-V LVTTL`——Analysis & Synthesis 每次都正常通过（综合不校验电平标准词表），
到 Fitter 阶段全部以 169216 拒绝，并连锁 `Error (171000): Can't fit design in device`
与 293001 全编译失败（每次 4 errors, 4 warnings）；把 `led_b` 改回该器件支持的
`3.3-V LVTTL` 后同一套 `quartus_sh` Tcl 流程全编译 0 error 收官。

三个变体证明的是同一件事：Cyclone IV E 在 Quartus 25.1 下的合法 I/O 标准词表很窄，
凭其他器件族经验拼出的 LVCMOS/低电压名称不会被智能纠正，而是在 Fitter 准备阶段直接判非法。
最初想观察的「同一 bank 两种 VCCIO 电压互相冲突」场景，在这颗器件上根本走不到——
非法名称在更早的词表校验环节就被拦下，这本身就是排错时容易误判的点。

## 文件

- `io_conflict.v` —— 四个流程共用的唯一设计：24 位计数器驱动双路 LED，模块 `ic_top`
- `flow_bad_lvcmos25.tcl` —— 问题流程变体一：led_b 指派 `2.5-V LVCMOS`，预期 169216
- `flow_bad_lvcmos18.tcl` —— 问题流程变体二：led_b 指派 `1.8-V LVCMOS`，预期 169216
- `flow_bad_lvttl18.tcl` —— 问题流程变体三：led_b 指派 `1.8-V LVTTL`，预期 169216
- `flow_good.tcl` —— 修复流程：四个端口全部 `3.3-V LVTTL`，预期全编译 0 error
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 bad25/bad18c/bad18t/good 选择流程并落日志
- `err-169216-lvcmos25.log` / `err-169216-lvcmos18.log` / `err-169216-lvttl18.log`
  —— 三次问题流程的真实报错日志（精简规范化版）：综合 0 error 通过、Fitter 169216
  （io_conflict.v:8）+ 171000 + 293001（4 errors, 4 warnings）+ 23031
- `fix-compile-pass.log` —— 修复后真实全编译日志（全量 212 行）：
  `Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 三个问题流程：quartus_sh 非零退出，Fitter 阶段各出现一次 Error (169216)
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad25
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad18c
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow bad18t

# 修复流程：quartus_sh 退出码 0，日志含 Full Compilation was successful
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow good
```

也可以直接调用 Quartus Shell：

```bat
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_bad_lvcmos25.tcl
D:\altera_lite\25.1std\quartus\bin64\quartus_sh.exe -t flow_good.tcl
```

## 读数要点

- 169216 是 **Fitter 阶段**错误，且卡在 Fitter preparation（171121 之前）：RTL 与综合全程合法，
  问题只出在管脚约束的词表/器件支持矩阵，不要回头改设计代码。
- 报错文本同时给出两个事实——指派的完整名称（`I/O standard assignment '...'`）与判定
  （`not a valid I/O standard name`）；修法是查目标器件族支持的 I/O 标准清单换合法名称，
  而不是在 LVTTL/LVCMOS 词形之间来回猜。
- 171000（Can't fit design in device）是 169216 的下游连锁，不是芯片容量不够；
  根因消除后它自行消失，看到 171000 先向上翻第一条 Error。
- 同属管脚类问题但性质不同：未分配引脚只触发 169085 Critical Warning 且编译成功
  （见姊妹实验 ts-quartus-169085-pin-unassigned），输出脚放进输入专用脚是 169009 硬错误
  （见 ts-quartus-169009-input-only-pin），本篇是指派名称不被器件接受的第三类。
- 四次编译都出现 `Info (125061): Changed top-level design entity name to "ic_top"`，
  证明 Tcl 中的 `TOP_LEVEL_ENTITY` 显式指派生效。
