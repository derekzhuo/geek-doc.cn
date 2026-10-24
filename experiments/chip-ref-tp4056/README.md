# chip-ref-tp4056：LTspice CC/CV 充电全程实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/tp4056.html

## 复现方式

需要 LTspice（本实验用 26.1.1.2 for Windows）：

```powershell
LTspice.exe -b -ascii tp4056-charge.cir
```

批处理跑完生成 `tp4056-charge.log`（.meas 实测值）与 `.raw`。仓库内 `tp4056-ltspice.log` 是本次实测的原始输出。

## 实验设计

电池用 3600F 等效电容（1000mAh×3.6s=3600C/V）+0.15Ω 内阻，初始 OCV=3.0V；充电芯片按 datasheet 公式 IBAT=1.2V/RPROG 建模恒流档，端电压 4.2V 转恒压、电流跌到 C/10 终止。`.step` 扫三档 RPROG：1.2k（1A）/2k（0.6A）/10k（0.12A），`.meas` 量 CC 段时长、全程时长、进 CV 时的电池开路电压。

## 关键结论（本次实测）

- 1A 档：CC 段 **3780s（63 分钟）**、全程 5023s（84 分钟），进 CV 时电池 OCV 只有 **4.049V**。
- 0.6A 档：110/132 分钟，进 CV 时 4.110V；0.12A 档：9.8h/10.2h，进 CV 时 4.182V。
- 电流越大内阻压降越大，端电压越早「够到 4.2V」——大电流快充的代价是 CC 段提前退出、实际充入容量打折。
