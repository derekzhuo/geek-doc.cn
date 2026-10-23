# vivado-drc-nstd-ucio：Vivado DRC NSTD-1/UCIO-1 复现

**对应教程**：https://geek-doc.cn/fpga/beginner/ts-vivado-drc-nstd-1-ucio-1-bitstream.html（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-10-24；原始批处理输出见 `run.log`

## 复现方式

counter.v + counter.xdc（引脚约束）；flow.tcl 不带 xdc 跑 flow-noxdc.log（复现），带 xdc 跑 flow-xdc.log（对照出 bit）。Windows 下把 `vivado.bat`/`xvlog.bat` 全路径换成你的安装目录，按 run.log 里的命令序列逐条执行即可。

## 关键结论

无约束跑 write_bitstream 被 DRC 拦下：`[DRC NSTD-1]`（未指定电平标准）与 `[DRC UCIO-1]`（未分配引脚）各 4 处；补上 xdc 后全 flow 通过产出 counter.bit。
