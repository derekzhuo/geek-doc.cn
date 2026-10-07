# eda-lab-yosys-synth-steps

把 `yosys synth -top` 一把梭流程拆成单步逐步执行，每步后 `stat` 落盘，观察资源（线网/单元）随步骤的变化；并与 `synth -top` 对照组比较最终结果。

配套文档：geek-doc.cn《yosys synth 流程拆解》。

## 设计

- `uart_rx.v`：3 倍过采样串口接收器，5 状态 FSM（IDLE/START/DATA/STOP/CLEANUP），含两级同步器、位内计数器、移位寄存器。
- `uart_rx_noselfreset.v`：变体，仅把状态机的 `default: state <= IDLE;` 改为 `default: state <= state;`，用于演示「自复位电路导致 fsm 步骤跳过提取」这一真实行为（日志 `out/fsm_variant.log`）。

## 运行

Docker（推荐，环境锁定 geek-eda:0.1，yosys 0.33）：

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-yosys-synth-steps geek-eda:0.1 make run
```

本机装有 yosys 也可直接 `make run`。

## 产物（out/）

| 文件 | 内容 |
|---|---|
| `step_00_read.log` … `step_10_check.log` | 逐步日志，每步末尾带 `stat` |
| `s00.il` … `s09.il` | 各步之间的设计快照（write_ilang 接力） |
| `stat_summary.txt` | 各步 Number of wires/cells 汇总 |
| `oneshot_synth.log` | 对照组：`synth -top uart_rx` 一把梭完整日志 |
| `fsm_variant.log` | 变体实验：去掉自复位 default 分支后 fsm 成功提取状态机 |

步骤分组与 `yosys -p "help synth"`（yosys 0.33）打印的命令序列一一对应：

0. read_verilog + hierarchy（begin 段）
1. proc
2. opt_expr; opt_clean; check; opt -nodffe -nosdff
3. fsm
4. opt; wreduce; peepopt; opt_clean
5. alumacc; share; opt
6. memory -nomap; opt_clean
7. opt -fast -full; memory_map; opt -full（fine 段前半）
8. techmap
9. opt -fast; abc -fast; opt -fast
10. hierarchy -check; stat; check（check 段）

## 关键实测结论（yosys 0.33 / geek-eda:0.1）

- 逐步最终 223 cells / 190 wires；一把梭 220 cells / 187 wires——功能等价但计数差 3，逐步快照（write_ilang/read_ilang 接力）会引入少量边界差异。
- techmap 一步把 45 个高层次单元展开成 1022 个门级单元（$_MUX_/$_XOR_ 爆炸），随后 abc 收敛回 223。
- 主设计的 `default: state <= IDLE` 让 fsm 判定电路「自复位」而跳过状态机提取；变体去掉后成功提取并 auto 重编码。
