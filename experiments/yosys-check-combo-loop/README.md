# yosys-check-combo-loop

**对应教程**：https://geek-doc.cn/eda/ts-yosys-check-combo-loop.html（上线后生效）

Yosys `check` 报 `found logic loop`（组合逻辑环）的最小复现与修复实验。

## 文件

- `loop_bad.v` — 复现版：`a = c | d; c = a & e;` 两条 assign 互相依赖成环
- `loop_osc.v` + `tb_osc.v` — 反相组合环的仿真振荡演示（`en` 拉高后零时延振荡，仿真器卡死）
- `loop_fixed.v` — 修复版：环路上插入寄存器断开组合环

## 复现

```bash
yosys -p 'read_verilog loop_bad.v; proc; check'      # 报 found logic loop
iverilog -o loop_osc.vvp loop_osc.v tb_osc.v && vvp loop_osc.vvp   # 卡死，需外部超时强杀
yosys -p 'read_verilog loop_fixed.v; proc; check'    # Found and reported 0 problems.
```

环境：Yosys 0.33 / Icarus Verilog 13.0。运行 `vvp` 演示时请用外部看门狗（如 `timeout 3s`）保护。
