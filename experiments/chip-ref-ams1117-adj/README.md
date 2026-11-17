# chip-ref-ams1117-adj：AMS1117-ADJ 分压配比与 1.25V 基准实测

**对应教程**：<https://geek-doc.cn/chip-design/chip-ref/ams1117-adj.html>

## 复现方式

需要 LTspice（本实验用 26.1.1 for Windows）：

```powershell
.\run.bat
```

或分别执行：

```powershell
LTspice.exe -b ams1117_adj_ratio.cir
LTspice.exe -b ams1117_adj_step.cir
```

批处理跑完生成同名 `.log`（.meas 实测值）与 `.raw`（波形）。仓库内 `ratio-sweep.log`、`r2-step.log` 是本次实测的原始输出。

## 实验设计

行为级宏模型：OUT 与 ADJ 之间维持 1.25V 基准（1.1V dropout 钳位、25mΩ pass 电阻），ADJ 脚按 datasheet 典型值向分压节点注入 50µA 电流。B 源跨在输入与内部节点之间，负载电流真实取自电源：

- `ams1117_adj_ratio.cir`：12V 输入下两个固定配比单元对照——R1=120Ω、R2=360Ω（理想目标 5.0V）与 R1=120Ω、R2=720Ω（理想目标 8.75V），输入 4→14V 扫描求两个单元的 dropout 边界。
- `ams1117_adj_step.cir`：R1 固定 120Ω，R2 六档步进 120/240/360/480/680/820Ω，实测各档输出，对照公式 `Vout = 1.25×(1+R2/R1) + Iadj×R2`。六档目标均保留在 12V 输入的 dropout 余量内。

## 关键结论（本次实测）

- 两档配比实测 **5.012V / 8.776V**，与含 Iadj 项的公式值（5.018V / 8.786V）相差不超过 10mV，差异来自 25mΩ pass 电阻的负载压降。
- 六档 R2 步进实测 2.505 / 3.760 / 5.014 / 6.269 / 8.359 / 9.821V，与公式值逐项同量级吻合；R2 越大，Iadj×R2 项占比越高（820Ω 档约 41mV），精密输出不能忽略 ADJ 脚电流。
- dropout 边界：5.0V 配比 **6.07V**、8.75V 配比 **9.80V**——高输出电压档位要求更高的最小输入，选电源前先按「目标输出 + 1.1V」核算。
