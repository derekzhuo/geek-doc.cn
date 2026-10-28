---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/perf-read-flamegraph/`，配套页面 https://geek-doc.cn/demos/perf-read-flamegraph/


# perf-read-flamegraph —— 如何分析 perf 的图（动手复现）

> **代码获取**：本实验源码与一键复现脚本已随公开仓库发布，clone 即得：`git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git`，目录 `public/demos/perf-read-flamegraph/`。

配套讲解文章：[如何分析 perf 的图：火焰图/perf report/perf annotate 实战读图手册](/concepts/perf/perf-read-graph.md)。本目录提供可一键复现的源码、脚本和三张真实生成的火焰图 SVG。

> **更新时间**：2026-09-08

## 0. 这个实验演示什么

一个约 90 行的 C 程序 `hotspot.c`，刻意制造三种典型火焰图形态，并提供 `base` / `opt` 两个版本：

| 函数 | 形态 | base → opt |
|------|------|-----------|
| `hash_djb2` | 宽平顶叶子热点（重复算哈希） | 缓存为查表，self 占比 **21.16% → 0.30%** |
| `walk_array` | 中等宽度高原（顺序访存） | 不变，但相对占比因分母变小而升高 |
| `deep_chain → leaf_spin` | 又高又窄尖塔（深调用链空转） | 不变，充当对照组（56.63% → 56.50%） |

同时复现几个真实的坑：云主机硬件 PMU `not supported`、`--call-graph fp` 回栈断成 `[unknown]`、样本量与占比可信度、优化后占比反升的分母效应、单次计时被调度噪声干扰。

## 1. 实测环境

```bash
Linux 3.10.0-1160.el7.x86_64, 4 核 x86_64, load avg 0.01
gcc 4.8.5 (-O2 -g -fno-omit-frame-pointer -std=gnu99)
perf 3.10 (kernel-tools)
kernel.perf_event_paranoid = -1（普通用户可采样）
FlameGraph: Brendan Gregg 官方工具集
```

## 2. 准备 FlameGraph

```bash
git clone https://github.com/brendangregg/FlameGraph.git
export FG=$HOME/FlameGraph     # run_lab.sh 默认读 ~/FlameGraph
```

权限：若 `perf record` 报 Permission error，需 `sudo` 或让管理员 `sudo sysctl -w kernel.perf_event_paranoid=-1`。

## 3. 一键复现

```bash
make record          # 等价于 bash run_lab.sh
# 或手动：
gcc -O2 -g -fno-omit-frame-pointer -std=gnu99 hotspot.c -o hotspot
FG=$HOME/FlameGraph bash run_lab.sh
```

脚本依次执行：7 次计时 → 两版 `perf stat` → 两版 `perf record`（dwarf 回溯）→ self/children `perf report` → `perf annotate hash_djb2` → 折叠栈 + 两张火焰图 → 一张差分火焰图，结果写入 `images/`。

## 4. 本次真实结果

`perf report --no-children`（self 占比）：

```bash
base: leaf_spin 56.63% | hash_djb2 21.16% | walk_array 19.23%
opt : leaf_spin 56.50% | walk_array 36.56% | hash_djb2  0.30%
```

最小墙钟时间：base 0.44s → opt 0.31s（约 **−29%**；共享主机计时抖动大，须多次取最小值）。

`perf annotate hash_djb2` 热点集中在紧循环：两条 `add` 合计 62.68%、`movzbl` 取字符 26.06%。

## 5. 三张图怎么看

- `images/flame_base.svg`：顶部最宽平顶 `leaf_spin`(~56%)；`hash_djb2`(~21%) 坐在 `hash_all` 上。
- `images/flame_opt.svg`：`hash_djb2` 塌缩成 0.3% 细线；`leaf_spin` 不变；`walk_array` 视觉变宽是分母效应。
- `images/flame_diff.svg`：哈希栈呈蓝色（被优化消除）；参数顺序 `difffolded.pl folded_opt.txt folded_base.txt`，后一个是基准。

在浏览器打开 SVG 可交互：悬停看占比、点击放大子树、Ctrl-F 搜索函数。

## 6. 文件清单

| 文件 | 说明 |
|------|------|
| `hotspot.c` | 含三类热点形态的实验程序（base/opt 由命令行参数切换） |
| `run_lab.sh` | 一键复现脚本 |
| `Makefile` | build / record / svg / clean 目标 |
| `images/flame_base.svg` | 优化前 CPU 火焰图（真实采样） |
| `images/flame_opt.svg` | 优化后 CPU 火焰图（真实采样） |
| `images/flame_diff.svg` | opt vs base 差分火焰图（真实采样） |

## 一句话总结

这个实验用三类典型热点（宽平顶哈希、顺序访存高原、深链尖塔）演示火焰图全流程：缓存哈希优化使 self 从 21% 降到 0.3%，并提示读图要警惕占比分母效应、帧指针断栈和云主机无 PMU 等坑。
