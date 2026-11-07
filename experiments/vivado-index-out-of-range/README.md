# vivado-index-out-of-range：Vivado 位选越界告警复现

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-324-index-out-of-range.html>（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-11-08；原始批处理输出见 `synth-bad.log` / `synth-good.log`

## 复现方式

`range_bad.v` 在 4 位输入 `a[3:0]` 上读取 `a[5]`（复现），`range_fixed.v` 改为合法位选 `a[3]`（对照）。Windows 下把 `vivado.bat` 全路径换成你的安装目录，在本目录执行：

```bash
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-bad.tcl
# 两趟批处理之间先结束残留 vivado 进程并删除 .Xil，再跑对照
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-good.tcl
```

## 关键结论

`synth-bad.log` 命中 `WARNING: [Synth 8-324] index 5 out of range`，越界位选被综合工具按常量处理，告警级问题不会中断综合但会静默改变电路行为；对照组 8-324 消失，`Synthesis finished with 0 errors`。
