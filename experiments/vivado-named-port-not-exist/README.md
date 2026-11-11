# vivado-named-port-not-exist：例化命名端口不存在复现

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-448-named-port-not-exist.html>（上线后生效）

## 环境

- Vivado 2017.4（Windows，WebPACK 免费器件 xc7a35tcpg236-1）
- 日期：2026-11-08；原始批处理输出见 `synth-bad.log` / `synth-good.log`

## 复现方式

子模块 `and_sub.v` 只有 `a`、`b`、`y` 三个端口。`port_bad.v` 例化时多连了一个不存在的命名端口 `.c(c)`（复现），`port_fixed.v` 只连真实存在的 `a`/`b`/`y`，悬空的顶层输入 `c` 用 `wire unused_c = c` 保留（对照）。Windows 下把 `vivado.bat` 全路径换成你的安装目录，在本目录执行：

```bash
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-bad.tcl
# 两趟批处理之间先结束残留 vivado 进程并删除 .Xil，再跑对照
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source synth-good.tcl
```

## 关键结论

`synth-bad.log` 报 `ERROR: [Synth 8-448] named port connection 'c' does not exist for instance 'u_and' of module 'and_sub'`（port_bad.v:12），前置一条 `[Synth 8-4446] all outputs are unconnected` 告警，随后 `[Synth 8-285] failed synthesizing module` 与 `[Common 17-69]` 收尾，共 3 Errors；对照组 `Synthesis finished with 0 errors`，仅余 2 条未使用端口告警。
