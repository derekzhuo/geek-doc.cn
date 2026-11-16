# ts-xsim-sdf-annotation-fail

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-sdf-annotation-fail.html>（上线后生效）

XSim 时序后仿 SDF 标注失败的对照实验。实验把一个一级寄存器设计实现到 Artix-7 器件，生成 timesim 门级网表和配套 SDF，再分别使用功能仿真库与时序仿真库运行后仿。

- **错误用法**：timesim 网表已经触发 `SDF backannotation process started`，但 `xelab -L unisims_ver` 使用功能仿真库，找不到 SDF 中的时序延迟表达式，最终报 `ERROR: [XSIM 43-3462] Unable to annotate SDF delays in the design.`，仿真快照不会生成。
- **正确用法**：保持同一份 timesim 网表、SDF、testbench 和 `glbl.v` 不变，把 xelab 库改为 `simprims_ver`。XSim 输出 `INFO: [XSIM 43-3452] SDF backannotation was successful`，随后在 140 ns 检查点输出 `SDF_SIM_PASS q=1`。
- 不要用 `--sdfnoerror` 把标注错误降成警告；看不到 43-3452 就不是完整的时序后仿。

## 文件

- `sdf_probe.v` —— 一级寄存器 RTL 设计
- `write_timesim.tcl` —— 非工程模式综合、布局布线，并生成 timesim 网表与 SDF
- `timesim_netlist.v` —— Vivado 2017.4 生成的时序仿真网表，内含 `$sdf_annotate`
- `timesim.sdf` —— 与网表配套的 SDF 延迟文件
- `tb_sdf_probe.v` —— 后仿 testbench，120 ns 后改变输入，140 ns 检查输出
- `run_all.tcl` —— `xsim -tclbatch` 使用的运行脚本
- `generate-timesim.log` —— timesim 网表与 SDF 生成日志
- `bad-unisims-compile.log` / `bad-unisims-elaborate.log` —— 使用 `unisims_ver` 的失败对照
- `fix-simprim-compile.log` / `fix-simprim-elaborate.log` / `fix-simprim-simulate.log` —— 改用 `simprims_ver` 后的完整通过日志

## 复现（Windows，Vivado 2017.4）

先生成时序仿真网表和 SDF：

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source write_timesim.tcl
```

复现 `unisims_ver` 导致的 SDF 标注失败：

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat timesim_netlist.v tb_sdf_probe.v D:\Xilinx\Vivado\2017.4\data\verilog\src\glbl.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -L unisims_ver work.tb_sdf_probe work.glbl -debug typical -s timesim_embedded
```

改用时序仿真库完成后仿：

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat timesim_netlist.v tb_sdf_probe.v D:\Xilinx\Vivado\2017.4\data\verilog\src\glbl.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -L simprims_ver work.tb_sdf_probe work.glbl -debug typical -s simprim_external_glbl
D:\Xilinx\Vivado\2017.4\bin\xsim.bat simprim_external_glbl -t run_all.tcl
```

判断结果时先确认 xelab 日志同时包含 43-3451 和 43-3452，再运行 xsim 检查 `SDF_SIM_PASS q=1`。只有仿真 PASS、没有成功标注信息，不能当作时序后仿通过。
