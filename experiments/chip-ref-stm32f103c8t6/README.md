# chip-ref-stm32f103c8t6：XSim 复现 USART 波特率发生器双 APB 域实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/stm32f103c8t6.html

## 复现方式

需要 Vivado Simulator（本实验用 2017.4，Windows）：

```bat
xvlog tb_baud.v && xelab -debug typical tb -s sim && xsim sim -R
```

仓库内 `xsim-run1.log` 是本次实测的原始输出。

## 实验设计

Verilog 行为模型复现 STM32F103 的 BRR 过采样累加器语义：每个 APB 时钟累加 16，累到 BRR 进位产生一次 16 倍过采样 tick，等效 bit 周期 = BRR/APB 秒。115200 档两组时钟域同图对照：APB1=36MHz（BRR=313）与 APB2=72MHz（BRR=625，整除），实量 1024 个过采样 tick 的平均周期换算误差。

## 关键结论（本次实测）

- APB1（36MHz）：实际 115015.0 baud，误差 **−0.161%**（312.5 取 313 丢的半精度）。
- APB2（72MHz）：实际 115207.4 baud，误差 **+0.006%**（整除几乎零误差）。
- 两个时钟域都远在 ±2% 窗口深处，F103 跑 115200 完全不用操心。
