# chip-ref-lm2596：buck 输出纹波数值仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/lm2596.html（上线后生效）

## 复现方式

```bash
node buck-sim.js        # 或 sh run.sh
```

无需任何依赖，Node 18+ 直接跑。`buck.cir` 是同一电路的 ngspice 网表变体（有 ngspice 的机器上 `ngspice -b buck.cir` 可对照）。

## 说明

按 LM2596-5.0 datasheet 典型应用（Vin=12V → 5V/3A，150kHz，L=33µH，Cout=220µF/ESR 30mΩ）做逐周期分段线性数值积分，测稳态输出纹波并与 datasheet 公式组对照。`results.txt` 是真实运行输出。

## 关键结论

- 仿真实测纹波 **20.3mV**，公式组估算 19.9mV（电容 2.2mV + ESR 17.7mV），两者吻合。
- **纹波 89% 来自输出电容 ESR**——换低 ESR 固态/陶瓷电容比加大容量有效得多，这是 buck 选电容最容易踩反的点。
- 理想占空比 D=5/12 下仿真的输出均值约 4.71V（含 0.5V 续流二极管压降损耗）；真片靠闭环把占空比抬高补回 5V——这个差值正好说明「为什么 buck 一定要闭环」。
