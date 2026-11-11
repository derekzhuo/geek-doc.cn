# ts-xsim-assertion-failure

**对应教程**：<https://geek-doc.cn/eda/ts-xsim-assertion-failure.html>

XSim 仿真中 `$fatal` 断言失败的定位实验：4 位使能计数器本就会在 0..15 间回绕，
而检查器把合法上界错写成 9，计数到 10 的那一拍 `$fatal(1, ...)` 触发，仿真在
115 ns 提前终止；修正检查边界（4 位总线合法范围 0..15）后仿真跑到 212 ns 正常
`$finish`，断言不再触发。

## 文件

- `dut_counter.v` —— 4 位使能计数器，异步复位，天然 0..15 回绕
- `tb_assert_bad.v` —— 问题检查器：`cnt >= 10` 即 `$fatal`，边界与总线宽度不匹配
- `tb_assert_fixed.v` —— 修复检查器：边界改为 4 位总线真实上界 `cnt > 15`
- `xsim_run.tcl` —— XSim 批处理脚本：`run all` 后 `quit`
- `err-fatal.log` —— 问题版本真实仿真日志：`Fatal: bound check failed: cnt=10 exceeded 9`，115 ns 终止
- `fix-sim-pass.log` —— 修复版本真实仿真日志：无 Fatal，212 ns 正常 `$finish`

## 复现报错（Windows，Vivado 2017.4）

```bat
rem 问题版本：xelab 通过，xsim 运行到 cnt=10 时 $fatal 触发
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_counter.v tb_assert_bad.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_assert_bad
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_assert_bad -t xsim_run.tcl

rem 修复版本：断言边界与总线宽度对齐，仿真正常收尾
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_counter.v tb_assert_fixed.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_assert_fixed
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_assert_fixed -t xsim_run.tcl
```

注意所有设计文件都要带一致的 `` `timescale `` 声明，否则 xelab 阶段会先被
`ERROR: [XSIM 43-4099] ... doesn't have a timescale` 拦下，断言逻辑根本跑不到。
