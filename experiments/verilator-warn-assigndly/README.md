# verilator-warn-assigndly

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-assigndly.html

Verilator `%Warning-ASSIGNDLY` 复现与修复实验：代码里的 `#` 赋值延迟（`assign #5` / `q <= #10`）在 `--no-timing` 模式下被 Verilator 忽略，语义悄悄变化。

## 文件

- `assigndly_bad.v` — 报错版：连续赋值 `#5` + 过程赋值 `#10` 两种形态
- `assigndly_fixed.v` — 修复版：组合逻辑去延迟，时序延迟改显式打拍寄存器
- `tb_delay.v` — 对照 testbench：iverilog 下 `#5` 延迟真实生效，输入变化 5ns 后输出才跟上

## 复现

```bash
# 触发 ASSIGNDLY 告警（Verilator 5.x 需要显式 --no-timing）
verilator --lint-only -Wall --no-timing assigndly_bad.v

# 对照：事件驱动仿真里延迟生效
iverilog -o tb_delay.vvp tb_delay.v && vvp tb_delay.vvp

# 修复版零告警通过
verilator --lint-only -Wall assigndly_fixed.v
```

实测环境：Verilator 5.020（docker geek-eda:0.2）/ Icarus Verilog 13.0，2026-10-29。
