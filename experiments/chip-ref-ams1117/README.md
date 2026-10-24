# chip-ref-ams1117：LTspice dropout 临界与负载瞬态实测

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/ams1117-3-3.html

## 复现方式

需要 LTspice（本实验用 26.1.1.2 for Windows）：

```powershell
LTspice.exe -b -ascii ams1117-ldo.cir
```

批处理跑完生成 `ams1117-ldo.log`（.meas 实测值）与 `.raw`。仓库内 `ams1117-ltspice.log` 是本次实测的原始输出。

## 实验设计

行为级 LDO 模型，按 datasheet 取 dropout 1.1V，输出级 0.3Ω+330µF 一阶等效，输出电容 22µF/50mΩ ESR。`.step` 扫三个输入档（5V / 4.5V / 4.3V），负载 1ms 处 10mA→500mA 阶跃、3ms 回落，`.meas` 量稳态值、跌落最小值、恢复过冲。4.3V 档低于 3.3+1.1=4.4V 门槛，用来复现 dropout 掉压。

## 关键结论（本次实测）

- Vin=5V/4.5V：稳压 **3.297V**，500mA 阶跃跌到 **3.150V**（−147mV），回落无过冲。
- Vin=4.3V：输出只剩 **3.20V**，掉出稳压区；阶跃时跌到 3.05V。
- AMS1117-3.3 输入至少 4.4V——3.7V 锂电直供 3.3V 必然掉压，要换降压差 LDO 或 buck-boost。
