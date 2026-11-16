# ts-xsim-glbl-missing

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-glbl-missing.html>（上线后生效）

XSim 门级仿真缺少 UNISIM 全局复位模块 `glbl` 的对照实验。实验先把一个一级寄存器设计综合成门级网表，再分别执行缺少 `glbl.v` 和补全 `glbl.v` 的仿真流程。

- **缺少 `glbl.v`**：`xelab` 静态展开 UNISIM `BUFG` 时报告 `ERROR: [VRFC 10-91] glbl is not declared`，随后报告 `ERROR: [XSIM 43-3322] Static elaboration ... failed`，仿真快照不会生成。
- **补全 `glbl.v`**：编译 Vivado 安装目录下的 `data/verilog/src/glbl.v`，并把 `work.glbl` 与 testbench 一起交给 `xelab`。显式指定快照名 `glbl_sim` 后，`xsim glbl_sim` 可以正常加载，140 ns 时输出 `GATE_SIM_PASS q=1`。
- testbench 在 120 ns 后才拉高输入，给 UNISIM 门级模型的全局复位留出释放时间，避免把启动阶段的复位行为误判成寄存器失效。

## 文件

- `glbl_probe.v` —— 一级寄存器 RTL 设计
- `write_gate_netlist.tcl` —— 非工程模式综合并写出 `gate_netlist.v`
- `gate_netlist.v` —— Vivado 2017.4 生成的 UNISIM 门级网表
- `tb_glbl_probe.v` —— 门级仿真 testbench
- `run_all.tcl` —— `xsim -tclbatch` 使用的运行脚本
- `missing-glbl.log` —— 缺少 `glbl.v` 的真实报错输出
- `fixed-glbl.log` —— 补全 `glbl.v` 后仿真通过的真实输出

## 复现（Windows，Vivado 2017.4）

先生成门级网表：

```bat
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source write_gate_netlist.tcl
```

复现缺少 `glbl.v` 的报错：

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat gate_netlist.v tb_glbl_probe.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -L unisims_ver work.tb_glbl_probe -debug typical
```

补全 `glbl.v` 并运行门级仿真：

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat gate_netlist.v tb_glbl_probe.v D:\Xilinx\Vivado\2017.4\data\verilog\src\glbl.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -L unisims_ver work.tb_glbl_probe work.glbl -debug typical -s glbl_sim
D:\Xilinx\Vivado\2017.4\bin\xsim.bat glbl_sim -t run_all.tcl
```

如果 `xelab` 同时编译多个顶层，建议始终用 `-s` 显式命名快照，再把同一个名字传给 `xsim`，不要猜测默认快照名。门级仿真还应考虑 `glbl.GSR` 的启动复位阶段，激励不要在仿真刚开始的几十个纳秒内立即采样寄存器输出。
