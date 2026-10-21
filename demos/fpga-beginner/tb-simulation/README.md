---
description: 'Testbench 与仿真 demo 用 8 位 ALU 和上升沿检测两个被测模块，演示自检 testbench 怎么写：task 封装检查、定向加 300 条随机用例自动比对、统计 TESTS/ERRORS，iverilog 加 gtkwave 开源工具链即可跑。'
updated: 2026-09-05
---

# tb-simulation（Testbench 与仿真 · 配套 demo）

配套文档：[Testbench 与仿真：用 iverilog+gtkwave / Vivado Sim 验证你的逻辑](/fpga/beginner/04-testbench-simulation.md)。

这个 demo 用两个最简单的可综合模块当「被测对象(DUT)」，重点演示 **testbench 怎么写、怎么让仿真自己判断对错**：

| 文件 | 类型 | 说明 |
|------|------|------|
| `simple_alu.v` | 可综合 RTL | 8 位 ALU（与/或/加/减 + zero/进位标志），**组合逻辑**代表 |
| `simple_alu_tb.v` | testbench | 组合逻辑自检：`task` 封装检查、定向用例 + 300 条随机用例、参考模型自动比对、统计 `TESTS/ERRORS` |
| `edge_detector.v` | 可综合 RTL | 上升沿检测（输入打一拍），**时序逻辑**代表 |
| `edge_detector_tb.v` | testbench | 时序逻辑自检：时钟生成、复位序列、沿上施加激励、`$monitor` 打印、VCD 波形 |

## 仿真（iverilog + gtkwave，开源免费）

```bash
# 组合逻辑：自检测试台，直接看控制台 PASSED/FAILED
iverilog -o alu_sim simple_alu.v simple_alu_tb.v
vvp alu_sim
gtkwave simple_alu_tb.vcd

# 时序逻辑：同样自检，波形里看 rise_pulse 脉冲
iverilog -o edge_sim edge_detector.v edge_detector_tb.v
vvp edge_sim
gtkwave edge_detector_tb.v
```

没有 iverilog 的 Windows 用户：安装 [Icarus Verilog](https://steveicarus.github.io/iverilog/) 时勾选「Add to PATH」，gtkwave 随安装包附带；也可以直接在 Vivado 里新建仿真工程，把这四个文件加进去，`simple_alu_tb` / `edge_detector_tb` 设为仿真顶层，Run Simulation 即可。

## 怎么看结果

- **自检测试台**：跑 `vvp` 后控制台应打印 `TESTS=306  ERRORS=0` 和 `*** PASSED ***`（ALU：6 条定向 + 300 条随机）。有错会逐条 `[FAIL]` 打印实际值/期望值。
- **波形**：`gtkwave` 打开 `.vcd`，左侧把 DUT 的信号拖进来。edge 演示里能看到 `sig` 拉高后，`rise_pulse` 恰好拉高一个时钟周期。

## 一句话总结

**一句话总结**：这个 demo 用一个组合 ALU 和一个时序边沿检测器，演示了 testbench 的核心套路——生成时钟与复位、施加激励、用参考模型算出期望值、自动比对并统计错误、导出 VCD 波形；自检测试台不依赖肉眼看波形，是回归验证的基础。
