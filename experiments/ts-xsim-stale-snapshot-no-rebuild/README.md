# ts-xsim-stale-snapshot-no-rebuild

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-stale-snapshot-no-rebuild.html>（上线后生效）

XSim 仿真快照不会随源码自动重建的对照实验。很多人以为 `xsim` 会像
Makefile 一样检查源码时间戳，实际流程是三段独立命令：`xvlog` 编译进
work 库、`xelab` 生成快照、`xsim` 只加载已有快照——最后一步对源码改动
一无所知。

三步真机证据（测试台固定输入 a=1、b=0）：

1. **基线**：与门 `assign y = a & b`，完整三步流程，输出
   `SNAPSHOT_PROBE a=1 b=0 y=0`。
2. **陈旧快照**：把源码换成或门 `assign y = a | b`（`and_gate_or.v`
   覆盖），**不重新 xvlog/xelab 直接 xsim**，输出仍是
   `SNAPSHOT_PROBE a=1 b=0 y=0`——跑的还是旧快照，改动静默失效。
3. **完整重建**：重新 xvlog + xelab + xsim 后输出才变成
   `SNAPSHOT_PROBE a=1 b=0 y=1`。

另外实测：同一目录连续两次 `xelab` 同名快照不会报「snapshot 已存在」，
2017.4 静默覆盖、退出码均为 0，所以快照问题从来不是报错，而是「跑的
不是你以为的那份设计」。

## 文件

- `and_gate.v` —— 基线版本：与门 `y = a & b`
- `and_gate_or.v` —— 覆盖版本：或门 `y = a | b`，实验中用它替换 and_gate.v
- `tb_and.v` —— 测试台：固定 a=1、b=0，与门期望 y=0、或门期望 y=1
- `run_sim.tcl` —— 仿真脚本：`run all` 后 `exit`
- `baseline-and.log` —— 基线完整流程日志：y=0
- `stale-snapshot.log` —— 换源码后只跑 xsim 的日志：仍旧 y=0
- `fresh-rebuild.log` —— 重新完整三步后的日志：y=1

## 复现（Windows，Vivado 2017.4）

```bat
rem 1. 基线：完整三步
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat and_gate.v tb_and.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_and
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_and -t run_sim.tcl

rem 2. 覆盖源码后只跑 xsim（复现陈旧快照）
copy /y and_gate_or.v and_gate.v
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_and -t run_sim.tcl

rem 3. 重新编译细化后再仿真
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat and_gate.v tb_and.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_and
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_and -t run_sim.tcl
```

工程上的固定做法：每次改完源码按 xvlog → xelab → xsim 重跑整条链，
或在脚本开头清掉 `xsim.dir`、`.Xil`、`xsim.jou`、`webtalk.*`、`*.pb`，
保证快照没有旧状态可吃；看到仿真结果与改动「对不上」，先怀疑快照没
重建，而不是怀疑 RTL 写错。
