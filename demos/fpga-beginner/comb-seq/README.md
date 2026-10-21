---
description: '组合与时序逻辑 demo 用 4 个最小可综合模块讲透 Verilog 两大范式：组合逻辑 assign/always@(*) 加阻塞赋值防锁存器，时序逻辑 always@(posedge clk) 加非阻塞赋值带复位，自检 testbench 穷举验证。'
updated: 2026-09-05
---

# comb-seq（组合 / 时序逻辑可综合范式 · 配套 demo）

配套文档：[组合与时序逻辑：可综合 Verilog 的两大范式](/fpga/beginner/06-verilog-combinational-sequential.md)。

用 4 个最小模块把「可综合 Verilog 只有两大类电路」讲透，每个都对应文章里的标准范式：

| 文件 | 模块 | 类别 | 演示的范式 |
|------|------|------|-----------|
| `comb_seq.v` | `mux4` | 组合 | `assign` 连续赋值 + 三目 `?:` |
| `comb_seq.v` | `decoder_3to8` | 组合 | `always @(*)` + `case`，开头给默认输出**防锁存器** |
| `comb_seq.v` | `reg_en` | 时序 | `always @(posedge clk or negedge rst_n)` + 非阻塞 `<=`，异步复位、使能保持 |
| `comb_seq.v` | `counter_en` | 时序 | 时钟沿触发状态更新 + 计数回卷 |
| `comb_seq_tb.v` | — | 自检 tb | 组合逻辑**穷举输入组合**比对、时序逻辑**驱动时钟沿**验证复位/使能/计数/回卷 |

## 仿真

```bash
iverilog -o comb_seq_sim comb_seq.v comb_seq_tb.v
vvp comb_seq_sim        # 应打印 COMB/SEQ SELF-CHECK *** PASSED ***
gtkwave comb_seq_tb.vcd
```

## 记住的对照

- **组合**：`assign` 或 `always @(*)`，用阻塞 `=`，输出随输入立刻变，无时钟；`always @(*)` 里**每条路径都要给输出赋值**（先写默认值），否则推断出锁存器。
- **时序**：`always @(posedge clk ...)`，用非阻塞 `<=`，状态只在时钟沿变，带复位；没写 `else` 的分支自动保持。

## 一句话总结

**一句话总结**：可综合 Verilog 归根结底是两类电路——组合逻辑用 `assign`/`always @(*)`+阻塞 `=` 且必须覆盖所有输入路径防锁存，时序逻辑用 `always @(posedge clk)`+非阻塞 `<=` 带复位、状态沿时钟更新；tb 里组合逻辑穷举输入、时序逻辑驱动时钟沿，自检通过即范式正确。
