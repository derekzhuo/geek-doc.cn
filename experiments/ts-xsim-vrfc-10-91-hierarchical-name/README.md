# ts-xsim-vrfc-10-91-hierarchical-name

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-vrfc-10-91-hierarchical-name.html>（上线后生效）

XSim 层级路径引用错误的对照实验：测试台需要跨模块层级探测 DUT 内部信号
`internal_and`，坏版本把实例名写成了 `u_dut`（实际例化名是 `u_gut`），
`xvlog` 编译期就报 `[VRFC 10-91] u_dut is not declared`，随后
`xelab` 收尾 `[XSIM 43-3322] Static elaboration ... failed`，仿真快照
根本建不起来；修复版本把层级路径改回 `u_gut.internal_and`，三步全过，
20 ns 内打印 `HIER_NAME_FLOW_PASS internal=1 y=1`。

## 文件

- `gate.v` —— DUT：内部连线 `internal_and` 做与逻辑后输出到 `y`
- `tb_gate_bad.v` —— 坏版本测试台：层级引用写成不存在的 `u_dut.internal_and`
- `tb_gate.v` —— 修复版本测试台：正确路径 `u_gut.internal_and`，带结果核对
- `run_sim.tcl` —— 仿真脚本：`run all` 后 `exit`
- `err-hier-name.log` —— 真实报错日志：VRFC 10-91 + XSIM 43-3322
- `fix-sim-pass.log` —— 修复后真实日志：三步全过，打印通过标记

## 复现（Windows，Vivado 2017.4）

```bat
rem 坏版本：xvlog 报 [VRFC 10-91]，xelab 报 [XSIM 43-3322]
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat gate.v tb_gate_bad.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_gate_bad

rem 修复版本：编译、细化、仿真三步
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat gate.v tb_gate.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_gate
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_gate -t run_sim.tcl
```

坏版本日志里的关键签名：`ERROR: [VRFC 10-91] u_dut is not declared
[...tb_gate_bad.v:21]`，紧接着
`ERROR: [XSIM 43-3322] Static elaboration of top level Verilog design
unit(s) in library work failed.`。层级引用的解析在编译期就发生，报错行
指向测试台里写下跨层级路径的那一行；排查时先核对例化名与模块名是否
混用，再自顶向下逐层比对路径中的每个名字。
