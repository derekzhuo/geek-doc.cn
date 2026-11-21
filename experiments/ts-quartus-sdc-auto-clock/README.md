# ts-quartus-sdc-auto-clock

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-quartus-sdc-auto-clock.html>（随对应教程上线后生效）

Quartus Prime Lite 25.1 在 Cyclone IV E EP4CE6E22C8 上对同一份 64 级组合逻辑进行三档时序约束对照。实验验证：没有 SDC 并不等于时序分析跳过检查，本工具链会自动派生 1ns 时钟并报告违例；显式 1ns 约束仍不满足；20ns 约束下 setup slack 转正。

## 文件

- `ripple_chain.v`：输入、输出寄存的 64 级组合 XOR 链。
- `compile_nosdc.tcl`、`sta_nosdc.tcl`：不提供 SDC，观察自动约束和时序报告。
- `tight.sdc`、`compile_tight.tcl`、`sta_tight.tcl`：显式 1ns 时钟。
- `realistic.sdc`、`compile_realistic.tcl`、`sta_realistic.tcl`：显式 20ns 时钟。
- `run-quartus.ps1`：按 `nosdc`、`tight`、`realistic` 选择完整编译和 STA 流程。
- 三份日志：对应三次真实运行的规范化输出。

## 复现（Windows，Quartus Prime Lite 25.1）

```powershell
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow nosdc
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow tight
powershell -ExecutionPolicy Bypass -File run-quartus.ps1 -Flow realistic
```

工具路径在 `run-quartus.ps1` 顶部，按本机安装位置修改。时序未满足时 TimeQuest 返回非零，这是待分析的实验结果；不要仅以进程退出码判断脚本是否执行。

## 实测读数

| 流程 | 时钟 | Slow 1200mV 85C setup slack | 结果 |
|---|---|---:|---|
| 无 SDC | 自动派生 1ns | -3.057ns | 332012 缺少 SDC，随后仍出现时序违例 |
| 显式过紧约束 | `clk_fast` 1ns | -3.057ns | 332148 Timing requirements not met |
| 显式合理约束 | `clk_board` 20ns | +11.180ns | setup、hold、minimum pulse width slack 均为正 |

无 SDC 流程同时出现 `Critical Warning (332012)`，说明编译器明确指出约束缺失；后续负裕量来自自动约束，不应把它解释为“没有约束所以时序通过”。三档使用同一份 RTL 和器件，差异只在时序约束。
