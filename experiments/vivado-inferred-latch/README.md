# vivado-inferred-latch：Vivado 推断锁存器复现

**对应教程**：https://geek-doc.cn/fpga/beginner/ts-vivado-synth-8-327-inferred-latch.html（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-10-24；原始批处理输出见 `run.log`

## 复现方式

latch_bad.v 组合逻辑 if 缺 else（复现），latch_good.v 补全分支（对照）；sim.tcl + tb.v 出 VCD 波形观察保持行为。Windows 下把 `vivado.bat`/`xvlog.bat` 全路径换成你的安装目录，按 run.log 里的命令序列逐条执行即可。

## 关键结论

synth-bad.log 命中 `[Synth 8-327] inferring latch` ×2；对照组干净。锁存器保持行为可用 tb.v 仿真波形直观看。
