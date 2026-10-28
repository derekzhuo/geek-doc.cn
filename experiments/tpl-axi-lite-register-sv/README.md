# tpl-axi-lite-register-sv：AXI4-Lite 从机寄存器接口模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-axi-lite-register-sv.html

可直接复制进工程的 AXI4-Lite 从机寄存器接口 SystemVerilog 模板，含控制/状态/中断状态三组寄存器（AW/W/B 写通道握手、AR/R 读通道握手、寄存器写使能译码、读多路选择、中断 sticky 位 W1C 清除）。

## 文件

- `axi_lite_regs.sv` —— 模板本体，iverilog -g2012 / Verilator -Wall 均可过
- `tb_axi_lite_regs.sv` —— 最小自检 testbench（写回读、字节选通、中断置位与 W1C 清除）

## 复现

```bash
# 静态检查（需要 Verilator 5.x）
verilator --lint-only -Wall axi_lite_regs.sv

# 编译并仿真（需要 Icarus Verilog 13）
iverilog -g2012 -o tb_axi_lite_regs.vvp axi_lite_regs.sv tb_axi_lite_regs.sv
vvp tb_axi_lite_regs.vvp   # 期望输出 TEST PASS
```

## 寄存器映射

| 字节地址 | 名称 | 属性 | 说明 |
|---|---|---|---|
| 0x00 | CTRL | RW | bit[1:0] = {err_irq_en, done_irq_en}，其余位用户自定义 |
| 0x04 | STATUS | RO | bit[1:0] = {error_in, busy_in} 实时电平 |
| 0x08 | IRQ_STATUS | W1C | bit[1:0] = {err_sticky, done_sticky}，写 1 清除 |

中断输出 `irq = |(IRQ_STATUS & CTRL[1:0])`。
