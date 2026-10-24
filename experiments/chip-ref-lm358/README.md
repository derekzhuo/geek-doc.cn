# chip-ref-lm358：LTspice 反相放大增益与单电源削顶实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/lm358.html

## 复现方式

需要 LTspice（本实验用 26.1.1.2 for Windows）：

```powershell
LTspice.exe -b -ascii lm358-amp.cir
```

批处理跑完生成 `lm358-amp.log`（.meas 实测值）与 `.raw`。仓库内 `lm358-ltspice.log` 是本次实测的原始输出。

## 实验设计

行为级 LM358 模型，参数取 datasheet 典型值：开环增益 100dB、Vos=2mV、GBW=1MHz（主极点 10Hz）、单 5V 摆幅窗 [5mV, VCC−1.5V]。两组电路：增益组 Rin=1k、Rf=1k/10k/100k 三档（G=−1/−10/−100），信号 5mV/1kHz 叠加 2V 直流（与同相端偏置一致）；削顶组 G=−10、信号 250mV 验证摆幅极限。

## 关键结论（本次实测）

- 三档输出峰峰值 **10.0mV / 100mV / 994mV**——G=−100 档比理想少 0.6%（GBW 缩水，真片同样如此）。
- 削顶组输出被削在 **3.5V 与 5mV** 两条轨道上：LM358 高侧够不到 VCC（差约 1.5V），低侧到不了真正的 0V。
- 单 5V 供电下有效输出窗口约 0–3.5V，直流工作点必须摆在窗口中央。
