# ts-xsim-elab-timescale — xelab 报「模块缺 timescale」复现与修复

**现象**：`xelab` 编译时报错中止：

```
ERROR: [XSIM 43-4099] "counter4.v" Line 1. Module counter4 doesn't have a timescale but at least one module in design has a timescale.
```

**原因**：仿真设计中只要有一个模块（这里是 testbench）带 `` `timescale``，其余所有模块也必须带；缺失的模块会让 xelab 直接退出。

**文件**

| 文件 | 作用 |
|---|---|
| `counter4_nots.v` | 不带 `` `timescale`` 的计数器（复现报错用） |
| `counter4_good.v` | 带 `` `timescale 1ns/1ps`` 的计数器（修复版） |
| `tb_counter4.v` | testbench（自带 `` `timescale``） |
| `e1-error.log` | 报错现场原始日志（真实跑出来的） |
| `e2-fixed.log` | 修复后全通过原始日志 |

**复现（Windows + Vivado 2017.4，路径按本机 Vivado 安装目录改）**

```bat
:: A. 复现报错：counter4.v 用不带 timescale 的版本
copy counter4_nots.v counter4.v
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat counter4.v tb_counter4.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_counter4 -s sim_err
:: 预期：xelab exit=1，报 XSIM 43-4099

:: B. 修复：换成带 timescale 的版本，全套重跑
copy counter4_good.v counter4.v
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat counter4.v tb_counter4.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_counter4 -s sim_ok
D:\Xilinx\Vivado\2017.4\bin\xsim.bat sim_ok -R
:: 预期：三步 exit=0，打印 TEST PASS
```

**实验环境**：Windows 11（26200）/ Vivado 2017.4 / 2026-10-22。
