# ts-vivado-xdc-duplicate-clock

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-duplicate-clock.html>（上线后生效）

Vivado XDC 同一端口重复 `create_clock` 的对照实验：坏约束在唯一的时钟端口
`clk` 上先后定义 `clk_a`（10 ns）和 `clk_b`（7 ns）两个时钟。综合不会硬
失败，Vivado 给出 `CRITICAL WARNING [Constraints 18-1056] Clock 'clk_b'
completely overrides clock 'clk_a'`，先写的 `clk_a` 被整体覆盖，`report_clocks`
里只剩 7 ns 的 `clk_b`——约束冲突以静默覆盖收场，只看退出码发现不了。
删掉重复定义、只保留一个时钟后，时钟报告恢复为 10 ns 的 `sys_clk`，
CRITICAL WARNING 清零。

## 文件

- `clock_gate.v` —— 带使能的 4 位计数器，唯一时钟端口名为 `clk`
- `clocks_dup.xdc` —— 问题约束：同一 `[get_ports clk]` 上两次 `create_clock`
- `clocks_ok.xdc` —— 正确约束：只定义一个 `sys_clk`
- `x12_err.tcl` / `x12_fix.tcl` —— 非工程模式综合脚本，末尾 `report_clocks` 验证实际生效的时钟
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-dup-clock.log` —— 真实日志：Constraints 18-1056 覆盖告警（read_xdc 与综合期各一次），report_clocks 只剩 clk_b 7.000 ns
- `fix-single-clock.log` —— 修复后真实日志：report_clocks 输出 sys_clk 10.000 ns，无约束类 CRITICAL WARNING

## 复现（Windows，Vivado 2017.4）

```bat
rem 问题版本：综合不中断，clk_a 被 clk_b 静默覆盖
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x12_err.tcl

rem 修复版本：report_clocks 只输出 sys_clk 10.000 ns
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x12_fix.tcl
```

排查要点：① 同一对象上重复 `create_clock` 不是硬错误，Vivado 用后定义的
时钟整体覆盖先定义的，并伴随 18-1056；综合退出码仍为 0，必须把
CRITICAL WARNING 纳入失败判据。② 排查时以 `report_clocks` 的实际时钟表
为准——日志里出现过的时钟名不代表还活着，被覆盖的 `clk_a` 不会出现在
报告里。③ 多时钟设计应让每个时钟落在各自的源端口，或用
`create_generated_clock` 表达派生关系，而不是在同一端口上重复定义。
