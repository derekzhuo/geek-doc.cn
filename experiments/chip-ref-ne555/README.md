# chip-ref-ne555：LTspice 非稳态振荡频率/占空比实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/ne555.html

## 复现方式

需要 LTspice（本实验用 26.1.1.2 for Windows）：

```powershell
LTspice.exe -b -ascii ne555-astable.cir
```

批处理跑完生成 `ne555-astable.log`（三组 .meas 实测值）与 `.raw`。仓库内 `ne555-ltspice.log` 是本次实测的原始输出。

## 实验设计

555 内核行为级建模：两个比较器的 1/3、2/3 VCC 阈值用自引用 B 源施密特锁存复现，放电管用 Ron=20Ω 开关模型（体现约 0.1V 饱和压降）。VCC=5V，`.step` 扫三组 RC：① R1=1k R2=10k C=10nF；② 同阻值 C=100nF；③ R1=100Ω R2=100k C=10nF。`.meas` 量周期/频率/高电平占比，对照公式 f=1.44/((R1+2R2)·C)、duty=(R1+R2)/(R1+2R2)。

## 关键结论（本次实测）

- 组① **6621Hz** / 占空比 50.6%（公式 6857Hz / 52.4%）；组② **670.5Hz**；组③ **557Hz** / 占空比 **38.7%**。
- 常规阻值下公式误差 3–5%，估频够用。
- R1 极小（100Ω）时放电管饱和压降把占空比压到 50% 以下，理想公式失效——精确 50% 占空比要用二极管旁路 R2 的改型电路。
