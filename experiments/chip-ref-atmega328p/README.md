# chip-ref-atmega328p：XSim 复现 USART 波特率发生器实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/atmega328p.html

## 复现方式

需要 Vivado Simulator（本实验用 2017.4，Windows）：

```bat
xvlog tb_baud.v && xelab -debug typical tb -s sim && xsim sim -R
```

仓库内 `xsim-run1.log` 是本次实测的原始输出（编译 + MEAS 行）。

## 实验设计

Verilog 行为模型直接复现 ATmega328P 的 USART 波特率发生器硬件：16MHz 主频、UBRR 整数分频，U2X=0 时 16 倍过采样、U2X=1 时 8 倍。testbench 按 datasheet §24.3 公式取整 UBRR（115200 档：U2X=0 取 8、U2X=1 取 16），实量 64 个 bit 的平均位宽，反推实际波特率与误差。

## 关键结论（本次实测）

- U2X=0：实际 **111111.1 baud**，误差 **−3.549%**，出 ±2% 窗口（VERDICT 行直判）；与 datasheet 误差表 −3.5% 逐位吻合。
- U2X=1：实际 **117647.1 baud**，误差 **+2.124%**，压在可用区边缘。
- **16MHz 的 328P 跑 115200 必须开 U2X**；230400 以上整数分频物理给不出，要换 14.7456MHz 波特率友好晶振。
