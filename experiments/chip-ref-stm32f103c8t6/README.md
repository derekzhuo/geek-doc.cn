# chip-ref-stm32f103c8t6：USART 波特率误差实测计算

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/stm32f103c8t6.html（上线后生效）

## 复现方式

```bash
node baud-error.js
```

无需任何依赖，Node 18+ 直接跑。

## 说明

按 ST RM0008 §27.3.4 的 BRR 取整规则，计算 STM32F103 在标准 72MHz 配置下 USART1（APB2 72MHz）与 USART2/3（APB1 36MHz）两组时钟域对 11 档标准波特率的实际误差。`results.txt` 是真实运行输出。

## 关键结论

- 72MHz/36MHz 下 1200–115200 全部零误差，230400 起出现 ±0.160% 量级误差，全部远在 ±2% 可用线内。
- 同片两组 APB 时钟误差谱不同：38400 在 APB2 零误差、APB1 上 -0.053%——选哪个 USART 接对误差敏感的外设（如某些 GPS/4G 模组）有讲究。
