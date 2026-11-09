# ts-xsim-x-propagation-hang

**对应教程**：<https://geek-doc.cn/eda/ts-xsim-x-propagation-hang.html>（上线后生效）

XSim 仿真「假死」实验：testbench 声明了 `start` 却全程不驱动，信号保持 X 态，
`wait (start === 1'b1)` 永远等不到事件，仿真看起来挂住不动，只能靠看门狗
`$finish` 兜底。修复版在复位期间把 `start` 拉成确定的 0，随后正常给脉冲，
`wait` 苏醒、计数器推进，仿真提前正常结束。两份 testbench 共用同一个 DUT，
差异只在激励是否给出确定电平。

## 文件

- `dut_xhang.v` —— 带使能的 4 位计数器，`start === 1` 时计数，DUT 本身正确
- `tb_xhang_bad.v` —— 问题版本：`start` 只声明不驱动（恒 X），`wait` 永不苏醒，500 ns 看门狗兜底
- `tb_xhang_fixed.v` —— 修复版本：复位期驱动 `start=0`，两个 initial 块并行给脉冲，`wait` 正常苏醒
- `xsim_run.tcl` —— `run all` 后退出，看门狗保证坏版本也不会无限挂起

## 复现（Windows，Vivado 2017.4）

```bat
rem 问题版本：500 ns 看门狗打印 start=x is_x=1，全程无 GO observed
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_xhang.v tb_xhang_bad.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_xhang_bad
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_xhang_bad -t xsim_run.tcl

rem 修复版本：脉冲后打印 GO observed，仿真在看门狗窗口前正常收尾
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_xhang.v tb_xhang_fixed.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_xhang_fixed
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_xhang_fixed -t xsim_run.tcl
```

注意 `$isunknown` 是 SystemVerilog 系统函数，Verilog 模式的 `xvlog` 会报
`[VRFC 10-2696] system call isunknown not allowed in this dialect`，本工程
改用 Verilog-2001 合法的 `(start === 1'bx)` 做 X 判定。
