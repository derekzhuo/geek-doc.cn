# ts-xsim-no-finish-run-all-hang

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-xsim-no-finish-run-all-hang.html>（上线后生效）

XSim 测试台缺少 `$finish` 导致 `run all` 永不退出的对照实验。

- **坏版本**：自由时钟（`always #5 clk = ~clk`）加 `forever` 计数循环，
  全文件没有任何 `$finish`。`xsim` 加载快照执行 `run all` 后永远等不到
  结束条件，90 秒守护窗口内打印了 **2,184,358 条** `NO_FINISH_TICK`
  （8 位 `cnt` 自然回绕），被守护进程强杀，作业日志标记
  `NO_FINISH_HANG_CONFIRMED`。
- **修复版本**：把 `forever` 改成 `repeat (10)`，计满 10 个时钟沿后
  `$display("NO_FINISH_FLOW_PASS cnt=10")` 并 `$finish`，三步流程正常
  退出。

## 文件

- `tb_no_finish.v` —— 坏版本：自由时钟 + forever 计数，无 `$finish`
- `tb_with_finish.v` —— 修复版本：repeat 10 后 `$finish`，带结果核对
- `run_sim.tcl` —— 仿真脚本：`run all` 后 `exit`
- `run-xsim-redirect.bat` —— 守护实验用包装器：把 xsim 输出重定向到日志文件，便于外部限时守候
- `err-no-finish-hang.log` —— 编译细化日志与 90 秒守护判定 marker
- `xsim-run-excerpt.log` —— 坏版本 xsim 输出节选（头尾各 30 行；完整运行 90 秒产出 218 万余行、约 51MB，存档于实验记录）
- `fix-sim-pass.log` —— 修复后真实日志：`NO_FINISH_FLOW_PASS cnt=10`，正常退出

## 复现（Windows，Vivado 2017.4）

```bat
rem 坏版本：run all 不退出，需要外部限时守护
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat tb_no_finish.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_no_finish
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_no_finish -t run_sim.tcl

rem 修复版本：计满 10 个时钟沿后自行结束
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat tb_with_finish.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_with_finish
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_with_finish -t run_sim.tcl
```

交互模式下这个坑表现为仿真「卡住」、提示符不返回；批处理模式下会一直
烧机直到外部超时。排查信号：日志里 TICK 类输出持续滚动、仿真时间不停
增长但作业不结束。固定写法是每个测试台都给出明确的终止条件—— stimulus
跑完即 `$finish`，需要看门狗时用 `initial #10000 $finish` 兜底，而不是
依赖 `run all` 自己停下来。
