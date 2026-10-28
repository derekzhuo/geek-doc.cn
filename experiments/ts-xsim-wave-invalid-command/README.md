# ts-xsim-wave-invalid-command — XSim 报 `invalid command name "wave"`

**对应教程**：https://geek-doc.cn/fpga/beginner/ts-xsim-wave-invalid-command.html（极客工场站点对应篇目，上线后此链接即生效）

**现象**：把 ModelSim 的 `wave add` 脚本直接拿给 XSim 跑，仿真器报：

```bash
invalid command name "wave"
```

波形永远加不上，GUI 模式下波形窗也永远等不出来。

**原因**：XSim（Vivado 2017.4）没有 ModelSim 的 `wave add` / `wave zoom` 命令族，对应命令是 `add_wave`；时间轴缩放也没有 `wave zoom full`，要改 `.wcfg`（本质是 XML）里的 `<ZoomStartTime>/<ZoomEndTime>` 再 `open_wave_config`。

**文件**

| 文件 | 作用 |
|---|---|
| `counter4.v` / `tb_counter4.v` | 4 位计数器 DUT 与 testbench |
| `wave_bad.tcl` | ModelSim 语法 `wave add`（复现报错用） |
| `wave_good.tcl` | XSim 正确语法 `add_wave`（修复版） |
| `wave-invalid.log` | 报错现场原始日志 |
| `wave-fixed.log` | 修复后原始日志 |

**复现（Windows + Vivado 2017.4）**

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat counter4.v tb_counter4.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_counter4 -s sim_w
:: A. ModelSim 语法 → invalid command name "wave"
D:\Xilinx\Vivado\2017.4\bin\xsim.bat sim_w -tclbatch wave_bad.tcl
:: B. XSim 语法 → 正常跑完
D:\Xilinx\Vivado\2017.4\bin\xsim.bat sim_w -tclbatch wave_good.tcl
```

**实验环境**：Windows 11（26200）/ Vivado 2017.4 / 2026-10-22。
