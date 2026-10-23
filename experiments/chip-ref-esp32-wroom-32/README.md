# chip-ref-esp32-wroom-32：UART 波特率误差实测计算

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/esp32-wroom-32.html（上线后生效）

## 复现方式

```bash
node baud-error.js
```

无需任何依赖，Node 18+ 直接跑。

## 说明

ESP32 的 UART 时钟源为 APB 80MHz，分频器是「整数 + 1/16 小数」结构。本脚本按该硬件结构实算 1200–2000000 共 13 档波特率的实际误差，`results.txt` 是真实运行输出。

## 关键结论

- 小数分频让 ESP32 全档位误差 ≤0.008%，比 STM32 的 1/16 分辨率 BRR 在高波特率段（230400 起）优约 20 倍。
- 1M/2M 高速档整除零误差——ESP32 接高速串口外设（如 2M 波特率的激光雷达）没有误差顾虑。
