# chip-ref-ch340g：两端误差叠加判定（CH340 × 常见 MCU）

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/ch340g.html（上线后生效）

## 复现方式

```bash
node stack-judge.js        # 无需任何依赖，Node 18+ 直接跑
```

## 说明

串口能否通信取决于发送端与接收端波特率误差之和是否落在接收容忍窗（本实验取 ±2%）。脚本把 CH340 侧按 datasheet 保证的 <0.3% 最坏情况计，MCU 侧用各自真实分频公式实算：STM32F103（APB1 36MHz，BRR 1/16 分辨率）、ATmega328P（16MHz，UBRR 整数分频，U2X 开/关）、ESP32（80MHz，4bit 小数分频）。逐组合输出 MCU 侧误差 / 叠加误差 / 绿红判定。`results.txt` 是真实运行输出。

## 关键结论

- STM32/ESP32 × CH340：全档位绿（叠加 ≤0.46%），CH340 的 0.3% 不构成瓶颈。
- ATmega328P × CH340：**57600 起不开 U2X 即红**；115200 开 U2X 后叠加 2.42% 压红线（零裕量）；≥230400 全灭。
- 瓶颈永远在 MCU 侧整数分频，判通断要算两端之和。
