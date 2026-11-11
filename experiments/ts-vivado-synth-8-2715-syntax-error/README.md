# ts-vivado-synth-8-2715-syntax-error

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-2715-syntax-error.html>

Vivado 综合 `ERROR: [Synth 8-2715] syntax error near ...` 行号定位实验：一条连续
赋值漏写行尾分号，解析器在下一个 `assign` 关键字处无法继续，报 8-2715 并连带
`[Synth 8-2350] module ... ignored due to previous errors`，整个模块被跳过；补回
分号后同一份综合流程零错误收官。实验展示「报错 token 在前、真正出错位置在上一行
末尾」这个解析类报错的典型定位规律。

## 文件

- `syntax_bad.v` —— 问题版本：第一条 `assign y = a & b` 漏分号，下一条 assign 处触发 8-2715
- `syntax_fixed.v` —— 修复版本：补回分号，综合零错误
- `v3_err.tcl` / `v3_fix.tcl` —— 综合脚本，`read_verilog` 后 `synth_design -part xc7a35tcpg236-1`
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-syntax-8-2715.log` —— 真实报错日志：8-2715（syntax_bad.v:12）+ 8-2350 模块忽略 + Common 17-69
- `fix-synth-pass.log` —— 修复后真实综合日志（0 error / 0 critical warning / 0 warning）

## 复现报错（Windows，Vivado 2017.4）

```bat
rem 问题版本：解析器在第 12 行 assign 处报 8-2715，真正漏分号的是第 11 行末尾
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v3_err.tcl

rem 修复版本：补分号后综合零错误
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v3_fix.tcl
```

8-2715 的 `near <token>` 给的是「解析崩溃点」而非错误本身，定位时从该位置向上回看
一到两行，优先检查行尾分号、`end`/`endmodule` 配对与括号闭合。
