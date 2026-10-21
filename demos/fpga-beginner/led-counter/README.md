---
description: 'FPGA 第一个工程 demo 用时钟分频加计数器驱动 LED 闪烁，配套 testbench 与 XDC 约束模板，走通「iverilog 仿真 → 综合 → 下载上板」全流程的最小闭环，Vivado/Quartus 通用。'
updated: 2026-09-05
---

# led-counter（FPGA 入门第一个工程）

配套文档：[第一个工程：LED 与计数器](/fpga/beginner/03-first-project-led-counter.md)。

| 文件 | 说明 |
|------|------|
| `led_blink.v` | 可综合 RTL：时钟分频 + 计数器驱动 LED 闪烁，Vivado/Quartus 通用 |
| `led_blink_tb.v` | testbench，用小参数加速仿真，输出 VCD 波形 |
| `constraints.xdc` | Xilinx 约束模板（时钟 + 管脚），管脚号需按开发板替换 |

## 仿真（iverilog + gtkwave）

```bash
iverilog -o sim led_blink.v led_blink_tb.v
vvp sim
gtkwave led_blink_tb.vcd   # 看 led 每 5 个时钟周期翻转一次
```

## 上板

在 Vivado/Quartus 新建工程、选对器件型号，加入 `led_blink.v` 与约束文件，
把 `constraints.xdc` 里的 `clk`/`rst_n`/`led` 管脚改成你板子原理图上的引脚号，
综合 → 实现 → 生成比特流 → 下载，即可看到 LED 约 1 秒闪烁一次。

## 一句话总结

**一句话总结**：这个 demo 用「计数器数到 N 就翻转 LED」实现了可参数化的闪烁电路，仿真时用小参数快速验证翻转逻辑、上板时把参数换回真实时钟频率，是走通 FPGA「仿真→综合→下载」全流程的最小闭环。
