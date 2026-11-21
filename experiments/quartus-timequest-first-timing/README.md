# quartus-timequest-first-timing

**对应教程**：<https://geek-doc.cn/fpga/beginner/quartus-timequest-first-timing.html>（随对应教程上线后生效）

用同一份 64 级组合逻辑对照无 SDC 和显式 20ns 时钟的 TimeQuest 输出，重点阅读时钟来源、分析模型、latch edge、data arrival、data required 和 slack，而不是只看最后的 PASS/FAIL。

## 复现（Windows，Quartus Prime Lite 25.1）

```powershell
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow nosdc
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow realistic
```

工具路径在脚本顶部，按本机安装位置修改。两档分别使用独立工程 `timing_nosdc` 与 `timing_realistic`，器件均为 Cyclone IV E EP4CE6E22C8，RTL 不变。

## 报告对照

| 项目 | 无 SDC | 显式 `clk_board` 20ns |
|---|---|---|
| 时钟来源 | 332012 警告后自动 `derive_clocks -period 1.0` | `realistic.sdc` 的 `create_clock` |
| setup latch edge | 1ns | 20ns |
| Slow 1200mV 85C setup slack | -3.057ns | +11.180ns |
| 同模型 hold slack | +1.149ns | +1.486ns |
| 同模型 minimum pulse width slack | -3.000ns | +9.781ns |

`nosdc.log` 和 `realistic.log` 保留真实运行的规范化输出。无 SDC 流程中 `Full Compilation was successful` 只表示编译流程完成；同一日志同时存在 `Timing requirements not met` 与负裕量，不能用编译成功替代时序收敛判断。

负 setup slack 来自 1ns 检查要求不足，负 minimum pulse width slack 则说明时钟高低电平宽度也触碰器件限制。阅读报告时要把两类违例分开，不要试图用同一个修改同时解释所有红色数字。
