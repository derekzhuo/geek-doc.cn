# ts-xsim-vrfc-10-1412-syntax-error

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-vrfc-10-1412-syntax-error.html>（上线后生效）

XSim 编译期语法错误的对照实验：同一个 D 触发器模块，坏版本在 `always`
块的阻塞赋值末尾漏写分号，`xvlog` 分析到 `endmodule` 时报
`[VRFC 10-1412] syntax error near endmodule`，并连带
`[VRFC 10-1040] module dff_bad ignored due to previous errors`，模块整体
被丢弃；修复版本补上分号后，`xvlog` / `xelab` / `xsim` 三步全部通过，
测试台在 25 ns 打印 `DFF_SYNTAX_FLOW_PASS q=1`。

## 文件

- `dff_bad.v` —— 坏版本：`q <= d` 后漏分号，触发 VRFC 10-1412
- `dff.v` —— 修复版本：同一 D 触发器，补分号
- `tb_dff.v` —— 测试台：两个时钟沿后核对 `q`，通过则打印 `DFF_SYNTAX_FLOW_PASS`
- `run_sim.tcl` —— 仿真脚本：`run all` 后 `exit`
- `err-vlog-syntax.log` —— 真实报错日志：VRFC 10-1412 + VRFC 10-1040
- `fix-sim-pass.log` —— 修复后真实日志：三步全过，25 ns 打印通过标记

## 复现（Windows，Vivado 2017.4）

```bat
rem 坏版本：xvlog 报 [VRFC 10-1412]，模块被忽略
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dff_bad.v

rem 修复版本：编译、细化、仿真三步
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dff.v tb_dff.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_dff
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_dff -t run_sim.tcl
```

坏版本日志里的关键签名：`ERROR: [VRFC 10-1412] syntax error near
endmodule [...dff_bad.v:11]`，下一行
`ERROR: [VRFC 10-1040] module dff_bad ignored due to previous errors`。
注意报错点定位在 `endmodule` 而不是漏分号的那一行——解析器走到下一个
 token 才发现语句没有结束，修这类报错要回看到报错行之前的最后一条语句。
