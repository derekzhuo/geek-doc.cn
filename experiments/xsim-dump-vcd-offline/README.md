# xsim-dump-vcd-offline — 批处理 dump VCD，离线看波形

**对应教程**：https://geek-doc.cn/fpga/beginner/xsim-dump-vcd-offline.html（极客工场站点对应篇目，上线后此链接即生效）

GUI 起不来 / 锁屏无人值守 / 截图黑图时，波形证据的替代路线：让 xsim 批处理把波形 dump 成 VCD，拿到能联网的机器上用任意 VCD 工具（GTKWave 等）离线打开。

**文件**

| 文件 | 作用 |
|---|---|
| `counter4.v` / `tb_counter4.v` | 4 位计数器 DUT 与 testbench |
| `vcd_setup.tcl` | `open_vcd → log_vcd → run all → close_vcd` 批处理脚本 |
| `vcd-dump.log` | 真实跑批日志（三步 exit 0） |
| `counter.vcd` | 真实 dump 出的波形数据（clk/rst_n/count，0→15 回卷） |

**复现（Windows + Vivado 2017.4）**

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat counter4.v tb_counter4.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_counter4 -s sim_vcd
D:\Xilinx\Vivado\2017.4\bin\xsim.bat sim_vcd -tclbatch vcd_setup.tcl
:: 产出 counter.vcd；拷走后 GTKWave 等离线打开
```

注意：`vcd_setup.tcl` 里的 `open_vcd` 路径与 `log_vcd` 的层级（`/tb_counter4/dut/*`）按自己工程改。

**实验环境**：Windows 11（26200）/ Vivado 2017.4 / 2026-10-22。
