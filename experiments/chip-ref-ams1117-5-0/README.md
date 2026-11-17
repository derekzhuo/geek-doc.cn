# chip-ref-ams1117-5-0：AMS1117 固定 5V 版 dropout 扫描与 12V 负载瞬态实测

**对应教程**：<https://geek-doc.cn/chip-design/chip-ref/ams1117-5-0.html>

## 复现方式

需要 LTspice（本实验用 26.1.1 for Windows）：

```powershell
.\run.bat
```

或分别执行：

```powershell
LTspice.exe -b ams1117_dropout.cir
LTspice.exe -b ams1117_loadtrans.cir
```

批处理跑完生成同名 `.log`（.meas 实测值）与 `.raw`（波形）。仓库内 `dropout-sweep.log`、`load-transient.log` 是本次实测的原始输出。

## 实验设计

行为级 LDO 宏模型，按 AMS1117 datasheet 取 dropout 典型值 1.1V、输出串联电阻 25mΩ、输出电容 10µF。同一张网表里放 5.0V 与 3.3V 两个单元，激励完全一致，便于直接对照固定电压版本差异：

- `ams1117_dropout.cir`：输入电压 4→12V 直流扫描，负载 100mA。`.meas` 求输出偏离标称 1% 时的输入电压（dropout 边界），以及 12V 输入下的稳态输出。
- `ams1117_loadtrans.cir`：12V 输入，负载电流 10mA→800mA 脉冲（10µs 边沿、2ms 高电平、4ms 周期）。`.meas` 量轻载标称输出、重载最低输出与高负载期间 LDO 自身耗散功率。

## 关键结论（本次实测）

- dropout 边界：5.0V 单元在输入 **6.0525V** 时输出跌破 4.95V（等效压差约 1.05V）；3.3V 单元对应边界 **4.3695V**（约 1.07V），与 datasheet 1.1V 典型值同量级。
- 12V 输入、100mA 负载：输出 **4.9975V / 3.2975V**，25mΩ 串联电阻造成 2.5mV 压降。
- 800mA 负载脉冲：最低输出 **4.9797V / 3.2797V**，跌落 20mV，两个固定版本一致（同一 pass 电阻、同一负载）。
- 高负载期 LDO 耗散：5.0V 单元 **5.616W**，3.3V 单元 **6.976W**——同样 SOT-223 封装、同样 800mA 负载下，输出电压越低、输入输出压差越大，发热越严重。12V 转 5V 大电流场景必须先算热账，必要时换开关稳压器。
