# ts-xsim-vcd-export-error — XSim 批处理导出 VCD 的报错与修复对照

**对应教程**：<https://geek-doc.cn/eda/xsim-vcd-wlf-export.html>（规划篇目，上线后此链接即生效）

同一个计数器 DUT，对照三份 Tcl 脚本：缺少 `open_vcd` 的错误调用、完整的 VCD 导出流程，以及 WDB 波形数据库写法。复现 XSim 批处理模式下 VCD 导出报错的触发条件与修复步骤。

## 文件

| 文件 | 作用 |
|---|---|
| `dut_toggle.v` / `tb_toggle.v` | 待仿真的 DUT 与 testbench |
| `xsim_vcd_bad.tcl` | 缺少 `open_vcd` 直接 `log_vcd` 的报错复现脚本 |
| `xsim_vcd_fixed.tcl` | `open_vcd → log_vcd → run all → close_vcd` 完整修复流程 |
| `xsim_wdb.tcl` | 改用 `log_wave` 导出 WDB 的对照脚本 |

## 复现（Windows + Vivado 2017.4）

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_toggle.v tb_toggle.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_toggle -s sim_toggle
D:\Xilinx\Vivado\2017.4\bin\xsim.bat sim_toggle -tclbatch xsim_vcd_bad.tcl
D:\Xilinx\Vivado\2017.4\bin\xsim.bat sim_toggle -tclbatch xsim_vcd_fixed.tcl
```

注意 `xelab` 必须带 `-debug typical`，否则 `open_vcd` 会因调试信息不足被拒绝。
