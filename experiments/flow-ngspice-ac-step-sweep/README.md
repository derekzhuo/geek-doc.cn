# ngspice AC 小信号与三档电阻扫描

**对应教程**：https://geek-doc.cn/eda/flow-ngspice-ac-step-sweep.html（上线后生效）

这个实验用 ngspice-42 驱动一个一阶 RC 低通：固定 C=100nF，依次令 R=1kΩ、2.2kΩ、4.7kΩ，每档从 10Hz 扫到 100kHz，每十倍频程 50 点。`.meas ac` 提取 -3dB 截止频率、1kHz 增益和截止点相位，`wrdata` 导出三组各 201 点的数据。

## 复现

准备 Docker 与 `geek-eda:0.5-asic` 镜像，然后在本目录执行：

```bash
make run
```

`run.sh` 执行 `ngspice rc_sweep.cir`，将原始输出保存为 `results/ngspice.log`，再用 `verify.awk` 检查恰好三档扫描、三项测量齐全，以及截止频率与 `1/(2*pi*R*C)` 的偏差小于 1%。输出文件 `results/ac_1k`、`results/ac_2.2k`、`results/ac_4.7k` 的第一列是频率，后两列依次是输出幅值 dB 和相位 rad。

`step_probe.cir` 是独立的语法边界实验。执行：

```bash
make probe
```

ngspice-42 会报告 `unimplemented dot command '.step'` 并以状态 1 退出。正式扫描因此使用 ngspice 原生的 `foreach rvalue ...`、`alter r1 = $rvalue` 和 `ac dec 50 10 100k`，不借用 LTspice 的 `.step` 写法。导出不加文件名后缀，避免该版本把 `$rvalue.data` 整体解析为变量名。
