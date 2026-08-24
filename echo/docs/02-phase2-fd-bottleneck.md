# 阶段 2：多线程扩展与 FD 上限（Day 4-6）——FD 上限已实测触发

> **本阶段的真实情况**：原计划是"扩大连接数直到撞上 EMFILE"，但实验环境从 Day 4 第一次压测起就预置了 `ulimit -n 65535`（见 [v1 环境准备](/demos/echo/day-04/split-experiment-v1.md#附录-b操作清单与命令记录)），FD 上限一度从未拦住过我们——连接数扫描全程 `fail = 0`。Day 4 真正推进的是**多线程 epoll（thread-per-core + SO_REUSEPORT）扩展**。
>
> **2026-08-17 实测回填**：随后在 [FD 墙实测](/demos/echo/day-04/fd-wall-experiment.md) 中把 `ulimit -n` 主动降档（1024/8192/65535 × 100~5000 连接），**第一次真实撞上了 FD 墙**：FD 峰值精确卡死 1024、EMFILE 刷屏、QPS -50%、P999 588ms——"若未预置会怎样"的假设路径（下节）已全部验证为实。

> 更新时间：2026-08-17（更正：阶段 2 的 FD 上限已由 [FD 墙实测](/demos/echo/day-04/fd-wall-experiment.md) 主动触发验证）
>
> 阶段小结：见 [阶段 2 阶段性小结](/demos/echo/docs/02b-phase2-summary.md)。

## 背景

阶段 1 证明了 Echo 服务在 100 并发下工作正常。原计划的下一关是"扩大连接数、撞上 FD 上限"，但 Day 4 起环境准备就预置了 `ulimit -n 65535`，FD 上限被提前移出瓶颈候选。Day 4 的实际主线（详见 [Day 4 报告](/demos/echo/day-04/split-experiment-v1.md)）：单线程 epoll 在 500 并发触顶（Day 3 结论）→ 用多线程（thread-per-core + SO_REUSEPORT）突破单线程天花板 → 再经三轮拆机实验（v1→v3）逐层下探到内核网络协议栈。

FD/ulimit 的完整概念仍是后续 10K/50K/百万连接阶段的必备前置知识，因此 Day 5/Day 6 的产出定位为"预备知识 + 预留检查"，而不是"故障修复"。

## 每日概览

| 天 | 主题 | 关键操作 | 产出 |
|:--:|------|------|------|
| Day 4 | [多线程 epoll 扩展（thread-per-core + SO_REUSEPORT）](/demos/echo/day-04/split-experiment-v1.md) | 线程数 1/2/4/8 扩展扫描、多线程下 LT vs ET、5000 短连接扫描；环境预置 `ulimit -n 65535` | 扩展收益量化（v1→v3 三轮拆机实验）；[FD 墙实测](/demos/echo/day-04/fd-wall-experiment.md)：降档 ulimit 主动撞墙 |
| Day 5 | [FD 与 ulimit 预备知识](/demos/echo/day-05/) | 理解 FD 三层限制模型：`ulimit -n`、`fs.file-max`、`fs.nr_open`、systemd LimitNOFILE | FD 概念图解、参数对照表；[FD 机制实测](/demos/echo/day-05/fd-mechanism-experiment.md) + [持续空转实测](/demos/echo/day-05/sustained-spin-experiment.md)（3x~78x 撞墙矩阵）+ [四层链诊断](/demos/echo/day-05/ulimit-chain-experiment.md)（"改完不生效"成因） |
| Day 6 | [预留 FD 余量并验证 10K](/demos/echo/day-06/) | 四层调参脚本幂等固化（`02-ulimit-setup.sh`：nr_open→hard→soft→limits.conf→file-max），验证 1 万连接稳定 | [10K 验证 + 泄漏检查](/demos/echo/day-06/10k-verify-experiment.md)：ok=200 万 fail=0、FD=10000+11、无泄漏 |

## FD 上限为什么没拦住我们？

```plantuml
@startuml
left to right direction
rectangle "FD 上限为什么没拦住我们" {
  (环境准备即预置 ulimit -n 65535) as A
  (Day 4 起每次实验前都执行) as B
  (连接数扫描全程 fail = 0) as C
  (FD 从瓶颈候选中移除) as D
  A --> B
  B --> C
  C --> D
}
@enduml
```

实验事实（证据链）：

1. v1 环境准备首步即 `ulimit -n 65535`（[v1 附录 B](/demos/echo/day-04/split-experiment-v1.md#附录-b操作清单与命令记录)），v2/v3 沿用同一准备（[v2 附录 A](/demos/echo/day-04/split-experiment-v2.md#附录-a命令记录)、[v3 附录 A](/demos/echo/day-04/split-experiment-v3.md#附录-a命令记录)）；
2. 连接数扫描（含 5000 短连接）`fail = 0`，全程无 `accept()` 返回 EMFILE / "Too many open files" 的记录；
3. 阶段 2 的真实瓶颈是**单线程 epoll 触顶**而非 FD 耗尽——多线程扩展把拐点从 500 并发推高后，才依次暴露 CPU 份额竞争 → 客户端 vCPU → 内核协议栈路径（见 [v3](/demos/echo/day-04/split-experiment-v3.md)）。

## 若未预置会怎样？——1024 默认值下的 EMFILE 诊断路径（已实测验证）

预置 ulimit 是为了压测数据干净（连接数不受进程级 FD 限制），但也意味着我们一度没见过 EMFILE。**2026-08-17 已在 [FD 墙实测](/demos/echo/day-04/fd-wall-experiment.md) 中把预置去掉、主动降档验证**——诊断路径完全命中：

```bash
连接数 ↗ → accept() 返回 -1 → errno = EMFILE
→ ulimit -n 显示 1024（默认值）
→ 每个 socket 占用一个 FD，1024 扣掉 stdin/stdout/stderr 只剩 ~1021
→ 连接数超出即失败
```

实测证据（详见 [FD 墙实测 5.1~5.3](/demos/echo/day-04/fd-wall-experiment.md#五实验数据)）：服务端 FD 精确卡死 1024（撞墙点连接数 2000）、`Too many open files` 刷屏 25588 次、5000 连接时吞吐 -50%、P999 588ms；客户端同限时 `socket()` 先失败、`fail` 大量。这段路径是排查"连接上不去"时的标准开场，可与 [analysis 速查表](/demos/echo/docs/analysis.md) 的 EMFILE 行对照。

## 完工验证清单（预留检查，非故障修复）

- [ ] `ulimit -n` ≥ 65535（实验会话内生效）
- [ ] `fs.file-max` ≥ 2097152
- [ ] 1 万连接 5 分钟不崩溃
- [ ] 能解释 FD 是什么、三层限制模型、每个连接占用哪些 FD

> **一句话总结**：阶段 2 原计划"撞 FD 上限"，但环境从一开始就预置 `ulimit -n 65535`，FD 从未真正拦住我们——Day 4 实际推进的是多线程扩展（thread-per-core + SO_REUSEPORT），FD/ulimit 作为预备知识保留下来，为后续 10K/50K/百万连接阶段预留余量。
