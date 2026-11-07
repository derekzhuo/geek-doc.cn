# vivado-force-not-supported：force/release 综合报错复现

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-27-force-not-supported.html>（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-11-08；原始批处理输出见 `synth-bad.log` / `synth-good.log`

## 复现方式

`force_bad.v` 把测试台风格的 `force`/`release` 写进可综合 RTL（复现），`force_fixed.v` 改用使能 mux 在一个 always 块内表达同样的覆盖意图（对照）。Windows 下把 `vivado.bat` 全路径换成你的安装目录，在本目录执行：

```bash
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-bad.tcl
# 两趟批处理之间先结束残留 vivado 进程并删除 .Xil，再跑对照
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-good.tcl
```

## 关键结论

`synth-bad.log` 综合直接中断，报 `ERROR: [Synth 8-27] force not supported`，连带 `[Synth 8-285] failed synthesizing module` 与 `[Common 17-69] Command failed`——`force`/`release` 是仿真控制语句，不属于可综合子集；对照组 `Synthesis finished with 0 errors`。同类语句在 iverilog 仿真里合法，仿真与综合的语言子集差异是这个坑的根源。
