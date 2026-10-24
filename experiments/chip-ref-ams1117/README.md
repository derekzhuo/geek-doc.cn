# chip-ref-ams1117：AMS1117-3.3 结温实算

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/ams1117-3-3.html（上线后生效）

## 复现方式

```bash
node thermal.js        # 无需任何依赖，Node 18+ 直接跑
```

## 说明

按 `Tj = Ta + (Vin-3.3)·Iout·θJA` 逐格计算 SOT-223 两种敷铜条件（θJA=90/61 °C/W）下 Vin∈{5,6,9,12}V × Iout∈{0.1..1}A 的结温矩阵，红线 125°C（死）/100°C（烫）。`results.txt` 是真实运行输出。

## 关键结论

- **12V 输入全档位阵亡**（最低档也 103°C）；12V→3.3V 请直接换 buck。
- 5V 输入下最小敷铜 0.5A 即烫、0.8A 死；加 1oz 敷铜 5V@1A 仍 129°C 越线——**标称 1A 是纸面参数**。
- 安全区 ≈ Vin≤6V 且 Iout≤0.3A；另有 dropout 暗坑：3.3V 版最小输入 4.6V。
