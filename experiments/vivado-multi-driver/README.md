# vivado-multi-driver：Vivado 2017.4 多驱动复现

**对应教程**：https://geek-doc.cn/fpga/beginner/ts-vivado-synth-8-3352-multiple-driver.html（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-10-24；原始批处理输出见 `run.log`

## 复现方式

bad.v 两个 always 块驱动同一 reg y（复现），good.v 单驱动（对照）。Windows 下把 `vivado.bat`/`xvlog.bat` 全路径换成你的安装目录，按 run.log 里的命令序列逐条执行即可。

## 关键结论

实际命中 `[Synth 8-3352] multi-driven net` CRITICAL WARNING ×2（注：2017.4 实测码是 8-3352，不是网文常引的 8-3331），综合仍完成但违例留进网表。
