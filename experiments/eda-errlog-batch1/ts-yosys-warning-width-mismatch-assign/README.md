# ts-yosys-warning-width-mismatch-assign

复现 Yosys `Warning: WIDTH: ... Width mismatch in assignment!`（8 = 4），
并用 iverilog 仿真展示隐式截断的真实后果（`8'h10 → 4'h0`）。

## 复现

```bash
bash run.sh
```

- `logs/warn-width-mismatch.log`：`assign y = a`（8 位 = 4 位）触发 WIDTH 告警。
- `logs/fix-explicit-extend.log`：`{4'b0000, a}` 显式扩展后 check 干净。
- `logs/sim-truncation.log`：testbench 打印 wide > 15 后窄总线数值回绕，
  对应 `sim/trunc_tb.v`，VCD 落 `sim/trunc.vcd`。

## 环境

Yosys ≥ 0.9、Icarus Verilog ≥ 11。

## 原始证据

本目录 `evidence/`（原始日志，与教程内嵌摘录同源）
