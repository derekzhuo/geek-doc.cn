# Yosys 手工 pass 链与 synth 宏对照实验

**对应教程**：https://geek-doc.cn/eda/flow-yosys-custom-pass-chain.html（上线后生效）

同一份带 FSM 与计数器的 RTL（`rtl/fsm_counter.v`），用三条综合链对照，回答「什么时候该绕开 `synth` 宏自己排 pass 链」：

1. **synth 宏基线**（`synth_macro.ys`）：一条 `synth -top` 跑默认序列，终态 53 cells。
2. **朴素手工链**（`manual_naive.ys`）：只凭直觉串 hierarchy/proc/opt/fsm/memory/techmap，缺 `wreduce`、`peepopt`、`alumacc`、`share`、`abc`、`opt_clean` 等化简 pass，终态膨胀到 88 cells。
3. **镜像完整链**（`manual_full.ys`）：从宏的真实日志逐 pass 提取序列手工重排，并在 proc/fsm/memory/techmap 后插只读 `stat` 留痕，终态 51 cells。

## 复现方式

```bash
bash run.sh
```

容器环境：Yosys 0.33（geek-eda 镜像）。脚本在 `build/` 下留三份完整日志。

## 实测摘要（2026-11-14，Yosys 0.33）

| 综合链 | 终态 cells | 与宏的差距 |
|---|---|---|
| synth 宏 | 53 | 基线 |
| 朴素手工链 | 88 | 多 35 个（+66%），缺化简 pass 的代价 |
| 镜像完整链 | 51 | 同量级，门级表达式不同（AND/OR/NOT 配比差异，逻辑等价） |

镜像链四阶段 stat 轨迹：16 → 16 → 16 → 51。前三个阶段统计的是 RTL 级高层单元（`$mux`/`$add` 等），`techmap` 把它们展开成门级原语后 cell 数才跳变——跨 techmap 边界的 cell 数不能直接比较。

镜像链与宏终态差 2 个 cell 的原因：手工重排后 ABC 看到的 AIG 输入结构与宏内部子 pass 的选择状态略有差别，门级分解方式不同（如 `$_ANDNOT_` 5 个对 15 个、`$_AND_` 15 个对 2 个），实现的是同一逻辑函数，面积同量级即视为收敛，不追求逐 cell 对等。
