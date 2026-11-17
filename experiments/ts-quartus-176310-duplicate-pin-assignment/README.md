# ts-quartus-176310-duplicate-pin-assignment

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-176310-duplicate-pin-assignment.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 命令行全编译复现 Fitter 重复管脚放置硬错误
`Error (176310): Can't place multiple pins assigned to pin location Pin_87 (IOPAD_X34_Y10_N7)`
的对照实验。同一份双路 LED 设计（`pc_top`，clk/rst_n/led_a/led_b 四端口），问题流程把
`led_a` 和 `led_b` 两个输出端口用两条 `set_location_assignment` 同时约束到 PIN_87，
Analysis & Synthesis 正常通过（综合只看 RTL，不检查脚位占用），Fitter preparation 阶段
报 176310，并用两条 `Info (176311)` 分别点名冲突双方（pin_conflict.v:6 与 :8），
连锁 `Error (171000): Can't fit design in device` 与 293001 全编译失败（4 errors, 3 warnings）；
把 `led_b` 拆到 PIN_86（同一 bank 的相邻通用 IO）后同一套 `quartus_sh` Tcl 流程
全编译 0 error 收官。

本站已有短答页《Quartus 管脚放不下：Can't place pin 的 IO 标准冲突与 bank 容量排查》
覆盖 VCCIO 冲突、bank 容量、差分对、专用配置脚四类原因，本实验补的是第五类独立变量——
同一物理脚被两个端口重复登记，且提供短答页没有的真机日志、可运行对照包与 176311 逐条点名证据。

## 文件

- `pin_conflict.v` —— 两个流程共用的唯一设计：24 位计数器驱动双路 LED，模块 `pc_top`
- `flow_bad.tcl` —— 问题流程：led_a 与 led_b 都约束到 PIN_87，预期 Fitter 176310 + 171000
- `flow_good.tcl` —— 修复流程：led_a→PIN_87、led_b→PIN_86 拆开，预期全编译 0 error
- `run-quartus.ps1` —— Windows PowerShell 包装器，按 bad/good 选择流程并落日志
- `err-176310-duplicate-pin.log` —— 真实报错日志（精简规范化版）：综合 0 error 通过、
  Fitter 176310 + 两条 176311（pin_conflict.v:6/:8）+ 171000 + 293001（4 errors, 3 warnings）+ 23031
- `fix-compile-pass.log` —— 修复后真实全编译日志（全量 212 行）：
  `Full Compilation was successful. 0 errors, 12 warnings`

## 复现（Windows，Quartus Prime Lite 25.1，Cyclone IV E EP4CE6E22C8）

```powershell
# 问题流程：quartus_sh 非零退出，Fitter 阶段出现 Error (176310)
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

- 176310 是 **Fitter 阶段**错误：RTL 与综合全程合法，问题纯粹在约束表，不要回头改设计代码；
  排查这类问题先确认报错阶段，综合通过不代表约束可实现。
- 176310 给冲突脚位，176311 给冲突双方的端口名与源文件行号——两条 Info 是定位重复登记的
  直接证据，修法是删掉其中一条 location 指派或把后分配的端口挪到别的通用脚。
- 171000（Can't fit design in device）是 176310 的下游连锁，不是芯片容量不够；
  根因消除后它自行消失，看到 171000 先向上翻第一条 Error。
- 管脚类三姊妹对照：未分配引脚只触发 169085 Critical Warning 且编译成功
  （ts-quartus-169085-pin-unassigned），输出脚放进输入专用脚是 169009 硬错误
  （ts-quartus-169009-input-only-pin），I/O 标准名不在器件词表是 169216 硬错误
  （ts-quartus-169216-invalid-io-standard），本篇是同一物理脚重复分配的 176310 硬错误。
- 两次编译都出现 `Info (125061): Changed top-level design entity name to "pc_top"`，
  证明 Tcl 中的 `TOP_LEVEL_ENTITY` 显式指派生效。
