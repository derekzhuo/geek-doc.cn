# CFS nice 权重与 CPU 时间占比对照基准

**对应教程**：https://geek-doc.cn/concepts/process/linux-cfs-nice-weight-throughput.html （随站点发布生效）

在 2 vCPU（1 物理核 2 SMT 线程）云主机上让两组燃烧进程超额订阅 CPU，
对照不同 nice 差值下两组实际拿到的 CPU 时间比例，并用 CFS 静态权重表
解释理论比值，实测 SMT 拓扑对公平性的扭曲。

| 组合 | A 组 nice | B 组 nice | 理论权重比（A/B） |
|---|---|---|---|
| `base` | 0 | 0 | 1.00（权重 1024/1024） |
| `n10` | 0 | 10 | 3.91（1024/262） |
| `n20` | 0 | 20 | 68.27（1024/15） |
| `neg10` | -10 | 0 | 2.25（2304/1024，需 root） |

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/nice_bench.c` | 固定墙钟时长的纯 CPU 燃烧进程，结束后自报 getrusage utime |
| `Makefile` | `-O2 -std=c11` 构建，产物在 `bin/`（不入库） |
| `run.sh` | 四组合各 5 次重复，getrusage 与 `/proc/PID/stat` 双口径算组间比，再用 perf stat 采调度事件 |
| `results.txt` | 最近一次 `run.sh` 的完整输出 |

## 复现方式

```bash
make                # 产出 bin/nice_bench
sudo bash run.sh    # 负 nice 与 perf 计数需要 root
# 单跑某个组合（perf 递归调用使用，不做中位汇总）：
bash run.sh --one "n10:0:10"
```

## 测量口径与边界

- 每组 2 个燃烧进程、两组共 4 个，对 2 vCPU 形成 2 倍超额订阅，
  保证运行队列里始终有任务在排队，nice 权重差异才会体现；
- 两个口径：进程内 `getrusage` 自报 utime（毫秒精度）与外层采样
  `/proc/PID/stat` 第 14 列 utime（jiffies，`getconf CLK_TCK` 通常为 100，
  粒度 10 ms，噪声更大但完全独立于被测进程）；
- 机器只有 1 个物理核、两个 SMT 兄弟线程，CFS 权重公平性在 SMT 拓扑下
  会被调度域均衡扭曲，实测比值偏离理论权重比是预期现象，不要拿本机数字
  与独立物理核机器横比；
- 未做 taskset 绑核、未碰 cgroup cpu.weight，nice 之外的调度参数全部默认。
