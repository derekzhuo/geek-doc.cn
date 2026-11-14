# THP 三策略（never / madvise / always）收益与代价对照基准

**对应教程**：https://geek-doc.cn/concepts/memory/linux-thp-madvise-always-benefit.html （随站点发布生效）

在 2 vCPU 云主机上对同一块 1 GiB 匿名缓冲区，对照透明大页（THP）三种启用策略
在缺页成本、AnonHugePages 占比、dTLB 缺失与访问相位耗时上的差异，区分
`madvise` 的缺页路径同步合并与 `always` 的 khugepaged 后台异步合并两条机制。

| 策略 | `/sys/.../enabled` | 程序是否 `madvise(MADV_HUGEPAGE)` | 大页来源 |
|---|---|---|---|
| never | `never` | 否 | 无，全部 4 KB 页 |
| madvise | `madvise` | 是 | 缺页路径同步合并 2 MB 页 |
| always | `always` | 否 | khugepaged 后台扫描合并 |

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/thp_bench.c` | 1 GiB 缓冲区分相位基准：缺页 → 等合并 → 线性/随机访问，自报 smaps 与 getrusage 计数 |
| `Makefile` | `-O2 -std=c11` 构建，产物在 `bin/`（不入库） |
| `run.sh` | 三策略 × seq/rand 两负载各 5 轮，perf stat 采 dTLB/缺页/上下文切换事件，输出 `results/summary.csv` 与中位数表 |
| `results/` | 每轮原始 perf 日志、汇总 CSV 与完整输出 |

## 复现方式

```bash
make
sudo ROUNDS=5 SIZE_MB=1024 PASSES=5 bash run.sh
# 脚本退出时自动恢复实验前的 THP enabled/defrag 设置
cat results/summary.csv

# 后台运行时用绝对路径重定向，避免 sudo -b 改变工作目录导致输出落到家目录：
sudo ROUNDS=5 SIZE_MB=1024 PASSES=5 bash \
  "$(pwd)/run.sh" > "$(pwd)/results/full-run.log" 2>&1
```

## 测量口径

- 缺页相位每 4 KB 读一次，`getrusage(RUSAGE_SELF).ru_minflt` 取增量；
  THP 命中时一次 minor fault 覆盖 2 MB（512 个基页），minflt 计数相应下降。
- `AnonHugePages`/`Rss` 直接读 `/proc/self/smaps` 汇总；`always` 策略额外轮询
  5 秒等待 khugepaged 合并，并记录实际等待耗时。
- perf 事件：`dTLB-load-misses,dTLB-loads,page-faults,minor-faults,major-faults,
  context-switches,cpu-migrations,cycles,instructions`，需要虚拟机透传 PMU。
- 每格 5 轮，报告中位数；单次实验数据不要外推到其他工作集大小或处理器型号。
