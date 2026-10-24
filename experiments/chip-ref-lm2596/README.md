# chip-ref-lm2596：LTspice buck 功率级输出纹波实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/lm2596.html

## 复现方式

需要 LTspice（本实验用 26.1.1.2 for Windows；macOS/Linux 版同命令）：

```powershell
LTspice.exe -b -ascii buck.cir
```

批处理跑完生成 `buck.log`（.meas 实测值）与 `buck.raw`（ASCII 波形）。仓库内 `buck-ltspice.log` 是本次实测的原始输出。

## 实验设计

按 LM2596 datasheet 典型应用搭开环 buck 功率级：Vin=12V，150kHz 固定频率、占空比 5/12 的理想开关（SW 模型）+ 0.5V 压降续流二极管 + L=33µH + Cout=220µF（Rser=30mΩ 模拟电解电容 ESR）+ 5Ω 负载（约 1A）。`.tran` 到 5ms 进稳态后 `.meas` 量输出均值/峰峰值与电感电流纹波，与公式组 ΔIL、ΔV_C=ΔIL/(8fC)、ΔV_ESR=ΔIL·ESR 对照。

## 关键结论（本次实测）

- 稳态输出均值 **4.970V**，纹波 **20.8mVpp**，电感电流纹波 **0.629A**（0.68–1.31A 三角波）。
- 公式组估算合计约 21mV，其中电容贡献 2.4mV、ESR 贡献 18.9mV——**纹波约九成来自电容 ESR 而不是容量**。
- 开环理想占空比下输出只有 4.97V（二极管压降损耗），真片靠闭环补回 5V——这个差值演示了 buck 为什么必须闭环。
