# ts-xsim-vrfc-10-2071-implicit-net-redeclare

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-vrfc-10-2071-implicit-net-redeclare.html>（上线后生效）

Verilog 声明顺序与隐式线网的对照实验，分三个层次展示「先用后声明」的
不同后果：

1. **硬错误**：`bus` 第一次出现在连续赋值里，被隐式推断成 1 位线网，
   下一行再显式声明 `wire [3:0] bus` 直接冲突，`xvlog` 报
   `[VRFC 10-2071] bus is already implicitly declared on line 8`，
   模块被 `[VRFC 10-1040]` 整体忽略。
2. **警告但能跑**：模块级条目里 localparam 先被引用、后声明，`xvlog`
   只给 `[VRFC 10-756] identifier W is used before its declaration`，
   编译细化仿真照常通过，输出 `WARN_USED_BEFORE cnt=f`——能跑不代表
   没有隐患。
3. **修复**：所有声明放在使用之前，三步全过且零警告，输出
   `REF_BEFORE_FLOW_PASS cnt=f`。

## 文件

- `order_bad.v` —— 硬错误版本：隐式 1 位线网与后续 4 位显式声明冲突
- `warn_used_before.v` —— 警告版本：localparam 先用后声明，VRFC 10-756 但通过
- `order_ok.v` —— 修复版本：声明在前、使用在后，零警告
- `run_sim.tcl` —— 仿真脚本：`run all` 后 `exit`
- `err-implicit-net.log` —— 硬错误真实日志：VRFC 10-2071 + VRFC 10-1040
- `warn-used-before.log` —— 警告层真实日志：VRFC 10-756，仿真仍输出 cnt=f
- `fix-sim-pass.log` —— 修复后真实日志：三步全过，打印通过标记

## 复现（Windows，Vivado 2017.4）

```bat
rem 硬错误：xvlog 报 [VRFC 10-2071]，模块被忽略
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat order_bad.v

rem 警告层：VRFC 10-756，但编译、细化、仿真都通过
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat warn_used_before.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat warn_used_before
D:\Xilinx\Vivado\2017.4\bin\xsim.bat warn_used_before -t run_sim.tcl

rem 修复版本：零警告通过
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat order_ok.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat order_ok
D:\Xilinx\Vivado\2017.4\bin\xsim.bat order_ok -t run_sim.tcl
```

排查要点：看到 `already implicitly declared` 先回查该标识符第一次出现
的位置——Verilog 默认 `default_nettype wire`，未声明标识符首次被使用
时会静默获得一个 1 位隐式线网，位宽和类型都可能不是你想要的；工程上
常用 `` `default_nettype none `` 把隐式推断直接变成编译错误，逼所有
信号显式声明。
