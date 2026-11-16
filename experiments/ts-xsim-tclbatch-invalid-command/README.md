# ts-xsim-tclbatch-invalid-command

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-tclbatch-invalid-command.html>（上线后生效）

XSim tclbatch 脚本三类执行结果的对照实验，测试台是同一个 8 拍计数器，
正常跑完会打印 `TCL_FLOW_PASS cnt=8`。

1. **非法命令**：脚本把 `run all` 误写成 `runall`，xsim 报
   `invalid command name "runall"` 并给出 Tcl 栈追溯，进程退出码 -1；
   批处理模式下报错后 xsim 退回 `xsim%` 交互提示符，stdin 没有后续输入
   时表现为挂起，需要外部超时守护回收。
2. **顺序写反**：脚本第一行就是 `exit`，`run all` 永远执行不到，xsim
   正常退出但测试台一行输出都没有（`TCL_FLOW_PASS` 出现次数为 0）——
   不报错的失败，最容易被当成「仿真通过」。
3. **正确流程**：`run all` 后 `exit`，打印 `TCL_FLOW_PASS cnt=8`。

## 文件

- `tb_tcl.v` —— 8 拍计数器测试台，结束打印 `TCL_FLOW_PASS cnt=8`
- `tcl_bad_cmd.tcl` —— 非法命令版：`runall` 拼写错误
- `tcl_bad_order.tcl` —— 顺序错误版：`exit` 在 `run all` 之前
- `tcl_good.tcl` —— 正确版：先 `run all` 再 `exit`
- `compile-elab.log` —— xvlog/xelab 编译细化日志
- `err-bad-command.log` —— 非法命令真实日志：`invalid command name "runall"` + 栈追溯 + RC=-1
- `err-bad-order.log` —— 顺序错误真实日志：零 `TCL_FLOW_PASS`，标记 ORDER_NO_RUN_CONFIRMED
- `fix-good-flow.log` —— 正确流程真实日志：`TCL_FLOW_PASS cnt=8`

## 复现（Windows，Vivado 2017.4）

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat tb_tcl.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_tcl

rem 非法命令：invalid command name，批处理下退回交互提示符
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_tcl -t tcl_bad_cmd.tcl

rem 顺序写反：静默不仿真，退出码仍是 0
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_tcl -t tcl_bad_order.tcl

rem 正确流程
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_tcl -t tcl_good.tcl
```

排查要点：① tclbatch 里的 Tcl 错误不会让进程立刻退出，而是落回
`xsim%` 提示符，无人值守流水线必须给 xsim 配超时守护，不能只等退出码；
② 退出码 0 不代表仿真跑过——要在日志里核对测试台自己打印的结束标记，
标记缺失即按失败处理；③ 脚本固定写成 `run all` 在前、`exit` 收尾，
命令名拿不准时先在交互提示符下用 `help` 核对。
