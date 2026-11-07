# vivado-ambiguous-clock：多时钟 always 综合报错复现

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-91-ambiguous-clock.html>（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-11-08；原始批处理输出见 `synth-bad.log` / `synth-good.log`

## 复现方式

`ambclk_bad.v` 在一个 always 块的敏感列表里同时写 `posedge clk1 or posedge clk2` 再用 if 选时钟（复现），`ambclk_fixed.v` 拆成两个独立时钟域的触发器、最后用 mux 合并输出（对照）。Windows 下把 `vivado.bat` 全路径换成你的安装目录，在本目录执行：

```bash
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-bad.tcl
# 两趟批处理之间先结束残留 vivado 进程并删除 .Xil，再跑对照
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-good.tcl
```

## 关键结论

`synth-bad.log` 综合直接中断，报 `ERROR: [Synth 8-91] ambiguous clock in event control`（指向 ambclk_bad.v:11），连带 `[Synth 8-285] failed synthesizing module` 与 `[Common 17-69] Command failed`——一个触发器只能有一个时钟，敏感列表里放两个时钟边缘无法映射到任何硬件单元；对照组每个触发器单一时钟、mux 合并，`synth_design completed successfully`。
