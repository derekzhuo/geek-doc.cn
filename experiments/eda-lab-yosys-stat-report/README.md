# eda-lab-yosys-stat-report

yosys `stat` 报表解读实验（geek-doc.cn eda-lab 系列文档配套代码）。

## 内容

- `counter.v` —— 8 位计数器（实验一：逐行解读 stat）
- `baud_top.v` / `baud_clk_div.v` / `baud_bit_cnt.v` / `baud_tx_fsm.v` ——
  带 FSM 的 UART 波特率发生器（四模块层级设计，实验二~五）
- `Makefile` —— 六组真实 yosys 运行，产物在 `out/`

## 运行

Docker（推荐，与本站文档同一环境 geek-eda:0.1，Yosys 0.33）：

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-yosys-stat-report geek-eda:0.1 make run
```

本机装了 yosys 也可以直接 `make run`。

## 产物（out/）

| 文件 | 内容 |
|---|---|
| `stat_counter.txt` | 计数器 synth 后的 stat 原文 |
| `stat_baud_flat.txt` | 波特率设计 `synth -flatten` 后整表 |
| `stat_baud_hier.txt` | 保留层级的 stat（各模块分表 + design hierarchy 汇总） |
| `stat_baud_fsm_sel.txt` | `select baud_tx_fsm` 后只统计单模块 |
| `stat_div.txt` / `stat_fsm.txt` | 两个子模块各自独立 synth 的 stat（与层级分表对照） |
| `synth_*.log` | 各次运行的完整综合日志 |

`make clean` 清除 out/。
