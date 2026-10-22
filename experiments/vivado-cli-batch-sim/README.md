# vivado-cli-batch-sim — Vivado 命令行批处理仿真（无 GUI）

不开 Vivado IDE，用 `xvlog → xelab → xsim -R` 三步批处理跑完一次行为仿真，适合 CI / 无人值守环境。

**文件**

| 文件 | 作用 |
|---|---|
| `counter4.v` | 4 位计数器 DUT |
| `tb_counter4.v` | testbench（$monitor 打印计数、回卷后 $finish） |
| `run.bat` | 一键三步脚本（改前三个路径变量即可） |
| `sim-batch.log` | 真实批处理日志（三步 exit 0、TEST PASS，全程约 6 秒） |

**用法**

```bat
:: 把 run.bat 里 XVLOG/XELAB/XSIM 三个路径改成本机 Vivado 安装目录
run.bat
```

**实验环境**：Windows 11（26200）/ Vivado 2017.4 / 2026-10-22。
