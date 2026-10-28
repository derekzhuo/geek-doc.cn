# 两级触发器同步器 Verilog 模板（two_flop_sync）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-two-flop-sync-verilog.html

单比特信号跨时钟域（CDC）最小模板：两级触发器同步器，三个变体。

| 文件 | 说明 |
|---|---|
| `two_flop_sync.v` | 基本版（无复位） |
| `two_flop_sync_rst.v` | 带异步复位版 |
| `two_flop_sync_edge.v` | 两级同步 + 上升沿检测，输出目标域单周期脉冲 |
| `tb_two_flop_sync.v` | testbench：源时钟 100MHz / 目标时钟 40MHz，展宽脉冲跨域验证 |

## 复现

```bash
# lint（Verilator 5.x）
verilator --lint-only -Wall two_flop_sync.v
verilator --lint-only -Wall two_flop_sync_rst.v
verilator --lint-only -Wall two_flop_sync_edge.v

# 仿真（Icarus Verilog）
iverilog -g2012 -o tb_two_flop_sync two_flop_sync.v two_flop_sync_rst.v two_flop_sync_edge.v tb_two_flop_sync.v
vvp tb_two_flop_sync
```

期望输出：`PASS: all pulses synchronized, edge version outputs single-cycle pulses`。

## 使用注意

- 只适用于**单比特**信号；多比特总线请用异步 FIFO 或握手协议。
- 异步输入脉冲宽度必须大于目标时钟一个周期（保守取 1.5 倍以上），否则先展宽再同步。
- 需要输出目标域单周期脉冲时，用边沿检测版，不要在基本版输出上再写电平判断。
