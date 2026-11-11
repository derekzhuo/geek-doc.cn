# ts-vivado-synth-8-439-module-not-found

**对应教程**：<https://geek-doc.cn/eda/ts-vivado-synth-8-439-module-not-found.html>

Vivado 综合 `ERROR: [Synth 8-439] module 'xxx' not found` 双触发路径对照实验：
同一个子模块找不到的报错，分别由「tcl 漏读源文件」与「实例化模块名拼写错误」
两条完全不同的路径产生，批处理日志逐字可对照；修复路径展示正确的
`read_verilog` 文件清单与模块名匹配后综合零错误。

## 文件

- `submod.v` —— 定义两输入与门 `mul_gate`，三个顶层共用
- `top_missing_file.v` —— 触发路径 A：实例名正确，但 tcl 没有 `read_verilog submod.v`
- `top_typo.v` —— 触发路径 B：文件已读，但实例化写成不存在的 `mull_gate`（双 l）
- `top_correct.v` —— 修复版本：文件清单完整且模块名与定义一致
- `v2a_err_file.tcl` / `v2b_err_typo.tcl` / `v2_fix.tcl` —— 三条综合脚本
- `run-vivado.ps1` —— Windows 批处理包装器，处理连续批跑的辅助进程句柄占用
- `err-file-missing.log` / `err-name-typo.log` —— 两条路径的真实报错日志（均为 Synth 8-439 + 8-285 + Common 17-69）
- `fix-synth-pass.log` —— 修复后真实综合日志（0 error / 0 critical warning / 0 warning）

## 复现报错（Windows，Vivado 2017.4）

```bat
rem 路径 A：漏读 submod.v → Synth 8-439 module 'mul_gate' not found
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v2a_err_file.tcl

rem 路径 B：模块名拼写错误 → Synth 8-439 module 'mull_gate' not found
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v2b_err_typo.tcl

rem 修复：文件清单与模块名都正确 → 综合零错误
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source v2_fix.tcl
```

两条报错路径的 8-439 行都带着实例语句的精确文件行号，可直接对照源码定位
是「文件没进工程」还是「名字对不上定义」。
