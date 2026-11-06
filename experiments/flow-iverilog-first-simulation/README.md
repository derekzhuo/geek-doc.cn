# flow-iverilog-first-simulation：iverilog 第一次仿真最小完整流程

**对应教程**：https://geek-doc.cn/chip-design/beginner/flow-iverilog-first-simulation.html

用 Icarus Verilog 13.0 跑通的最小仿真流程：写 testbench → `iverilog` 编译 → `vvp` 运行 → 看 VCD 波形。

## 文件

| 文件 | 作用 |
|------|------|
| `counter.v` | 被测设计（DUT）：4 位带使能递增计数器，异步低有效复位，计到 15 时 `carry` 拉高 |
| `tb_counter.v` | testbench：产生 10ns 周期时钟与复位/使能激励，导出 `wave.vcd`，并做逐拍自校验 |
| `Makefile` | `make run` 自动编译并运行 |

## 复现

```bash
make run        # iverilog -g2012 -Wall -o sim.vvp counter.v tb_counter.v && vvp sim.vvp
```

预期最后两行输出：

```text
RESULT: PASS  final q=8
tb_counter.v:52: $finish called at 502000 (1ps)
```

运行后当前目录生成 `wave.vcd`，用 GTKWave 打开：

```bash
gtkwave wave.vcd
```

## 激励说明

- 0ns 起复位有效，22ns 释放，复位期间 `q=0`；
- 释放复位后使能保持关闭 4 拍，验证 `en=0` 时计数保持；
- 62ns 拉高 `en`，连续使能 40 拍：40 = 2×16 + 8，计数器回卷两次后停在 8；
- 462ns 拉低 `en`，再观察 2 拍，计数保持不变，仿真在 502ns 结束。

`sim.vvp`、`wave.vcd` 为编译/运行产物，`make clean` 删除。
