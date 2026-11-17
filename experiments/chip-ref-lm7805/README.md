# chip-ref-lm7805：LM7805 输入扫描与 12V 负载瞬态、热账实测

**对应教程**：<https://geek-doc.cn/chip-design/chip-ref/lm7805.html>

## 复现方式

需要 LTspice（本实验用 26.1.1 for Windows）：

```powershell
.\run.bat
```

或分别执行：

```powershell
LTspice.exe -b lm7805_input_sweep.cir
LTspice.exe -b lm7805_load_transient.cir
```

批处理跑完生成同名 `.log`（.meas 实测值）与 `.raw`（波形）。仓库内 `input-sweep.log`、`load-transient.log` 是本次实测的原始输出。

## 实验设计

行为级宏模型按 LM7805 datasheet 取 dropout 电压 2.0V、输出串联电阻 25mΩ、静态接地电流 5mA；B 源跨在输入与内部节点之间，负载电流真实取自电源：

- `lm7805_input_sweep.cir`：输入 6→25V 直流扫描，500mA 固定负载。`.meas` 求输出跌破 4.95V 的 dropout 边界、7V/12V/25V 三点输出，以及 12V 与 25V 工况下器件自身耗散功率（含静态电流项）。
- `lm7805_load_transient.cir`：12V 输入，负载 100mA→1A 脉冲（10µs 边沿、2ms 高电平、4ms 周期），量轻载输出、重载最低输出与高负载期耗散功率。

## 关键结论（本次实测）

- dropout 边界 **6.9625V**（输出 4.95V 时等效压差约 2.01V），7V 是 LM7805 输出 5V 的实际最低输入，与 datasheet 2V 压差一致；对比 AMS1117 类 1.1V 压差 LDO，78 系列必须留更高输入余量。
- 7→25V 区间输出稳定在 **4.9875V**（500mA 下 25mΩ 串联电阻压降 12.5mV），线性调整率表现良好。
- 耗散功率随输入电压线性恶化：500mA 负载下 12V 输入 **3.57W**、25V 输入 **10.13W**；12V 输入、1A 负载脉冲高电平期 **7.09W**。TO-223/TO-220 封装无散热片时结温必然失控——78 系列大电流应用的核心约束是热设计而不是电流标称值。
