# ts-vivado-xdc-input-delay-no-clock

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-xdc-input-delay-no-clock.html>（上线后生效）

Vivado XDC 中 `set_input_delay` 参考时钟三种写法的对照实验，测试设计是
同一个带使能的 4 位计数器，输入端口 `en` 上挂 5 ns 输入延迟约束。

1. **不写 `-clock`**：Vivado 2017.4 并不报错，而是给
   `INFO: [Constraints 18-632] set_input_delay: No clock object specified,
   the clocks will be automatically identified`——工具替你猜参考时钟，
   约束被静默接受，多时钟设计里猜哪个时钟并不受你控制。
2. **写了不存在的时钟名**：`-clock no_such_clk` 触发
   `CRITICAL WARNING: [Vivado 12-4739] set_input_delay:No valid object(s)
   found for '-clock no_such_clk'`（解析 XDC 与综合期各一次），约束被
   丢弃，综合仍正常结束。
3. **显式写对参考时钟**：`-clock sys_clk`，零 ERROR、零 CRITICAL WARNING，
   延迟约束明确挂在 10 ns 周期的 `sys_clk` 上。

## 文件

- `clock_gate.v` —— 带使能的 4 位计数器，时钟端口 `clk`、使能输入 `en`
- `delay_bad.xdc` —— 不写 `-clock`：触发 18-632 自动识别
- `delay_badname.xdc` —— 引用不存在的时钟 `no_such_clk`：触发 12-4739
- `delay_ok.xdc` —— 正确写法：`-clock sys_clk`
- `x16_err.tcl` / `x16_badname.tcl` / `x16_fix.tcl` —— 非工程模式综合脚本，末尾 `report_clocks`
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-no-clock-arg.log` —— 真实日志：18-632 自动识别（流程内共 3 次）
- `err-bad-clock-name.log` —— 真实日志：12-4739 无有效时钟对象（2 次）
- `fix-input-delay.log` —— 修复后真实日志：零告警，sys_clk 10.000 ns

## 复现（Windows，Vivado 2017.4）

```bat
rem 不写 -clock：INFO 自动识别，不报错
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x16_err.tcl

rem 错时钟名：CRITICAL WARNING 12-4739，约束被丢弃
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x16_badname.tcl

rem 正确写法：告警清零
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source x16_fix.tcl
```

排查要点：① 输入延迟永远是「相对某个时钟」的约束，多时钟设计里省略
`-clock` 让工具自动选择，等于把时序语义交给猜解；② 时钟名拼错在
Vivado 里是 CRITICAL WARNING 而不是硬错误，综合退出码仍为 0，必须扫描
12-4739 一类消息并核对约束覆盖率；③ 修约束后重跑完整综合流程，确认
18-632/12-4739 都不再出现，而不是只改 XDC 不验证。
