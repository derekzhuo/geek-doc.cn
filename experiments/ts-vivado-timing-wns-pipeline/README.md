# ts-vivado-timing-wns-pipeline — 长组合逻辑时序违例与流水化修复对照

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-timing-wns-pipeline.html>（上线后生效）

这个实验在 Artix-7 `xc7a35tcpg236-1` 上构造同一条 64 级多路选择器链，时钟周期固定为 2 ns。坏版本把 64 级逻辑放在两级触发器之间，`route_design` 不会因为 WNS 为负而返回硬错误，但时序报告明确显示 setup 违例；修复版本保持 64 级逻辑总量不变，按每 2 级一组拆成 32 个流水段，在段间插入寄存器，把每条触发器到触发器路径压缩到 2 个逻辑级。

## 文件

| 文件 | 作用 |
|---|---|
| `mux_stage.v` | 单级多路选择器，外部 `sel` 防止组合链被常量折叠 |
| `mux_chain_bad.v` | 坏版本：64 级组合云夹在两级触发器之间 |
| `mux_chain_pipelined.v` | 修复版本：64 级逻辑拆成 32 组，每组 2 级，组间插入流水寄存器 |
| `timing.xdc` | 2 ns 时钟约束 |
| `run_synth_bad.tcl` | 坏版本综合、布局、布线与时序报告脚本 |
| `run_synth_pipelined.tcl` | 流水化修复版本的同类脚本 |
| `run-vivado.ps1` | Windows 批处理包装器，处理 Vivado 辅助进程句柄占用 |
| `results/err-64level-wns.log` | 坏版本真机综合与布线日志 |
| `results/fix-pipe2-met.log` | 2 级流水修复版本真机综合与布线日志 |

## 实测结果

| 设计 | 综合后 WNS | 布线后 WNS | 布线后 Logic Levels | Data Path Delay |
|---|---:|---:|---:|---:|
| 64 级组合云 | -36.175 ns | -43.524 ns | 64 | 45.493 ns |
| 每 2 级一级流水 | +0.033 ns | +0.103 ns | 2 | 1.864 ns |

坏版本的布线后路径由 10.023 ns 逻辑延迟和 35.470 ns 布线延迟组成，总延迟 45.493 ns，超出 2 ns 时钟周期；修复版本同项为逻辑 0.704 ns、布线 1.160 ns，总延迟 1.864 ns，保留 0.103 ns 正 slack。

## 复现步骤（Windows + Vivado 2017.4）

在 Vivado 2017.4 命令行环境中进入本目录，先运行坏版本：

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source run_synth_bad.tcl
```

再运行流水化修复版本：

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source run_synth_pipelined.tcl
```

也可以使用包装器，它会在连续批处理前清理辅助进程残留：

```powershell
powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl run_synth_bad.tcl -Log err-timing-wns.log
powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl run_synth_pipelined.tcl -Log fix-pipe2-timing.log
```

读报告时不要只看 Vivado 命令是否结束。`route_design` 在这个案例中可以正常完成，但 `report_timing_summary` 和 `get_timing_paths` 读到的 WNS 为负，设计仍未满足 2 ns 建立时间要求。流水化以增加延迟周期为代价换时序收敛：路径逻辑级从 64 降到 2，吞吐量可以跟随同一时钟继续工作，但输入到输出的等待周期增加。
