# chip-ref-tp4056：CC/CV 充电曲线数值仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/tp4056.html（上线后生效）

## 复现方式

```bash
node charge-sim.js        # 无需任何依赖，Node 18+ 直接跑
```

## 说明

简化 CC/CV 模型：恒流段 `IBAT = 1.2/RPROG(kΩ)`（datasheet 公式），电池电压用分段线性钴酸锂 OCV 曲线 + 0.15Ω 等效内阻，端电压达 4.2V 转恒压段，电流一阶衰减至 C/10 终止。输出 RPROG=1.2k/2k/3k/10k 全程耗时对照表 + 2kΩ 档逐 10 分钟曲线采样。`results.txt` 是真实运行输出。

## 关键结论

- 1000mAh 电池：1A 档 86 分钟、600mA 档 129 分钟、120mA 档 360 分钟。
- **CV 尾巴是固有代价**：CC 段 80 分钟充入约 85%，CV 段再拖 49 分钟——最后 5% 占 38% 时间。
- 1A 档不敷铜会触发热调节自动降流；600mA 是 1000mAh 电池的速度/发热平衡点。
