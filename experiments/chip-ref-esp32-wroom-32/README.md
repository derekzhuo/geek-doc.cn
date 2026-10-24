# chip-ref-esp32-wroom-32：XSim 复现 80MHz 小数分频 UART 双档实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/esp32-wroom-32.html

## 复现方式

需要 Vivado Simulator（本实验用 2017.4，Windows）：

```bat
xvlog tb_baud.v && xelab -debug typical tb -s sim && xsim sim -R
```

仓库内 `xsim-run1.log` 是本次实测的原始输出。

## 实验设计

Verilog 行为模型复现 ESP32 UART 的 CLKDIV 小数分频器：80MHz APB，分频比 = 整数部分 + 4bit 小数（1/16 分辨率），bit 周期 = CLKDIV/APB。两档实测：115200（CLKDIV=694.4375）与 ESP 系常用的 921600 高速烧录档（CLKDIV=86.8125），实量 64 个 bit 的平均位宽换算误差。

## 关键结论（本次实测）

- 115200 档：实际 115201.2 baud，误差 **+0.001%**。
- 921600 档：实际 921526.3 baud，误差 **−0.008%**。
- 对照同口径 STM32F103 定点 BRR 的 −0.161%（36MHz 域），小数分频把误差压低 1–2 个数量级——ESP 系敢把 921600 当默认烧录速率的底气就在这里。
