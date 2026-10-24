# chip-ref-ch340g：XSim 实测 UART 波特率误差失效边界

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/ch340g.html

## 复现方式

需要 Vivado Simulator（本实验用 2017.4，Windows）：

```bat
xvlog tb_uart_tol.v && xelab -debug typical tb -s sim_ch340g && xsim sim_ch340g -R
```

仓库内 `xsim-run1.log` 是本次实测的原始输出（25 档 MEAS 行）。

## 实验设计

Verilog 搭 UART 收发对：TX 按「标称 115200 × (1+err)」真实波特率背靠背连发 0x55/0xAA 共 50 帧（无空闲位，最严苛工况），RX 按标称波特率中点采样解码并校验停止位；err 从 −6% 扫到 +6%（步长 0.5%）统计误帧数，找失效边界。RX 带 20-bit 看门狗防止失步后无限等起始沿。

## 关键结论（本次实测）

- **−4.5% ~ +5.5% 区间 50/50 帧零误码**；−5.0% 整档全错（停止位采样点撞上后一帧起始位下降沿）；+6.0% 出现 25/50 误帧。
- 实测边界与理想中点采样理论极限 ±5.26% 吻合。
- 「两端叠加 ±2%」工程判据裕量巨大；115200 乱码的真凶几乎从来不是 CH340（自身 <0.2%），而是 MCU 侧时钟源误差。
