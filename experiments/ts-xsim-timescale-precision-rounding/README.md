# ts-xsim-timescale-precision-rounding — XSim 时间精度取整的无告警行为对照

**对应教程**：<https://geek-doc.cn/eda/ts-xsim-timescale-precision-rounding.html>（上线后生效）

这个实验用同一个亚纳秒翻转模型，对照 XSim 2017.4 在两种 DUT 时间精度下的行为：DUT 写成 `` `timescale 1ns/1ns `` 时，`#1.234` 会按 1ns 精度取整；DUT 写成 `` `timescale 1ns/1ps `` 时，同一延迟保留 1.234ns。testbench 固定为 `1ns/1ps` 并在 10ns 采样，两次仿真都正常结束且没有 warning，但采样值不同。

## 文件

| 文件 | 作用 |
|---|---|
| `dut_clock_ns.v` | 时间精度为 1ns 的 DUT，`#1.234` 被取整为 1ns |
| `dut_clock_ps.v` | 时间精度为 1ps 的 DUT，保留 1.234ns 延迟 |
| `tb_resolution.v` | 固定 `1ns/1ps` 的 testbench，在 10ns 打印采样值 |
| `run_sim.tcl` | 批处理仿真脚本，执行 `run all` 后退出 |
| `results/err-timescale-rounding.log` | 粗精度 DUT 的实际输出 |
| `results/fix-timescale-precision.log` | 1ps 精度 DUT 的实际输出 |

## 复现步骤（Windows + Vivado 2017.4）

在 Vivado 2017.4 的命令行环境中进入本目录，先运行粗精度 DUT：

```bat
rmdir /s /q xsim.dir
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_clock_ns.v tb_resolution.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_resolution
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_resolution -t run_sim.tcl
```

这一轮不会报 warning 或 error，10ns 采样结果为：

```text
TIMESCALE_SIM_TIME 10000 q=1
```

原因是 DUT 的精度为 1ns，`#1.234` 按精度取整后等价于 `#1`，信号在 1ns、3ns、5ns、7ns、9ns 翻转，到 10ns 时 `q=1`。

再清理快照，换成 1ps 精度的 DUT：

```bat
rmdir /s /q xsim.dir
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_clock_ps.v tb_resolution.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat tb_resolution
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_resolution -t run_sim.tcl
```

修复序列的 10ns 采样结果为：

```text
TIMESCALE_SIM_TIME 10000 q=0
```

此时翻转点为 1.234ns、2.468ns、3.702ns、4.936ns、6.170ns、7.404ns、8.638ns、9.872ns，10ns 前共翻转 8 次，`q=0`。两轮日志中的全局 `Time Resolution for simulation is 1ps` 都来自工程内最细的编译单元，不能替代 DUT 本地精度检查；排查亚纳秒延迟异常时，应先核对包含延迟语句的模块自身的 `` `timescale `` 精度。
