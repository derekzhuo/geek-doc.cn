# verilator-warn-casex 实验代码

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-casex.html

最小复现 Verilator `%Warning-CASEX`：casex 掩码把分支 `4'b1x11` 完全遮蔽成死代码。

- `casex_bad.v` / `tb_casex.v`：报错版（casex 优先级遮蔽演示）
- `casex_fixed.v` / `tb_fixed.v`：修复版（plain case + 显式枚举）

复现（需 Verilator 5.x 与 Icarus Verilog）：

```bash
verilator --lint-only -Wall casex_bad.v      # 触发 %Warning-CASEX
iverilog -o tb_bad.vvp casex_bad.v tb_casex.v && vvp tb_bad.vvp
verilator --lint-only -Wall casex_fixed.v    # 零告警
iverilog -o tb_fixed.vvp casex_fixed.v tb_fixed.v && vvp tb_fixed.vvp
```
