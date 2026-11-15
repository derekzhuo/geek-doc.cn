# ts-xsim-vcd-export-error — XSim 批处理导出 VCD 的报错与修复对照

**对应教程**：<https://geek-doc.cn/eda/ts-xsim-vcd-export-error.html>（上线后生效）

这个实验用同一个 4 位计数器，对照 XSim 2017.4 在批处理模式下导出 VCD 的两种编译方式：未启用调试信息时直接记录波形会触发 `[Simulator 45-10]`；清理旧快照后用 `-debug typical` 重新 elaborate，再按 `open_vcd → log_vcd → run all → close_vcd` 的顺序执行，即可生成 VCD。

## 文件

| 文件 | 作用 |
|---|---|
| `dut_toggle.v` / `tb_toggle.v` | 待仿真的 DUT 与 testbench |
| `xsim_vcd_bad.tcl` | 未启用调试信息时调用 `log_vcd`，复现 `[Simulator 45-10]` |
| `xsim_vcd_fixed.tcl` | 完整 VCD 导出流程 |
| `xsim_wdb.tcl` | 使用 `log_wave -r /` 生成 WDB 的对照脚本 |
| `results/err-vcd-no-open.log` | 报错序列的实际输出 |
| `results/fix-vcd-pass.log` | 重新编译并成功生成 VCD 的实际输出 |
| `results/wdb-wave-pass.log` | WDB 生成结果的实际输出 |
| `results/trace.vcd` | 修复后生成的 VCD 波形文件 |

## 复现步骤（Windows + Vivado 2017.4）

在 Vivado 2017.4 的命令行环境中进入本目录，先执行报错序列。注意这一步的 `xelab` 不带 `-debug`：

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_toggle.v tb_toggle.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_toggle
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_toggle -tclbatch xsim_vcd_bad.tcl
```

预期看到：

```text
ERROR: [Simulator 45-10] The current simulation was compiled without trace information.
To perform the requested operation, please recompile the design with -debug all or typical.
```

修复时先删除旧快照，避免 XSim 继续加载没有调试信息的 snapshot。Vivado 2017.4 的 `xelab` 不支持 `--force`，不要用这个选项代替清理：

```bat
rmdir /s /q xsim.dir
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_toggle.v tb_toggle.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_toggle
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_toggle -tclbatch xsim_vcd_fixed.tcl
```

修复序列会生成 `trace.vcd`。本次记录中文件大小为 1362 字节，VCD 内包含 `clk`、`rst_n` 和 `cnt[3:0]` 的变化。

如需生成 Vivado 波形数据库，可在同一调试快照上执行：

```bat
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_toggle -tclbatch xsim_wdb.tcl
```

本次记录生成的数据库文件名为 `work.tb_toggle.wdb`，大小为 5819 字节；仓库只保留生成日志，不提交带有本机工程路径的 WDB 二进制文件。
