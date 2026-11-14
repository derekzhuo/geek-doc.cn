# cgroup v2 cpu.max 带宽限制与节流延迟对照基准

**对应教程**：https://geek-doc.cn/concepts/container/linux-cgroup-v2-cpu-max-throttling.html （随站点发布生效）

在 2 vCPU 云主机上让双线程定长请求负载跑在三个 `cpu.max` 档位的 cgroup v2 里，
对照 CFS 带宽控制（CFS bandwidth control）造成的吞吐损失、请求尾延迟放大与
`cpu.stat` 节流计数，区分「配额小于核数 → 周期性节流」与「配额 ≥ 核数 → 不节流」
两个区间。

| 配置 | `cpu.max`（quota / period=100ms） | 含义 |
|---|---|---|
| p50 | `50000 100000` | 每 100ms 最多用 50ms，等价 0.5 核 |
| p100 | `100000 100000` | 每 100ms 最多用 100ms，等价 1 核 |
| p200 | `200000 100000` | 每 100ms 最多用 200ms，等价 2 核（本机满配） |

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/burner.c` | 固定墙钟时长的多线程定长请求负载，输出吞吐与 P50/P95/P99/P999 延迟 |
| `Makefile` | `-O2 -std=c11 -pthread` 构建，产物在 `bin/`（不入库） |
| `run.sh` | 三档各 5 轮，进程写入 `cgroup.procs`，前后快照 `cpu.stat` 算节流增量，输出 `results/summary.csv` 与中位数表 |
| `results/` | 每轮负载输出、汇总 CSV 与完整运行记录 |

## 复现方式

```bash
make
sudo ROUNDS=5 DURATION=10 THREADS=2 bash run.sh
cat results/summary.csv
# 脚本退出时自动 rmdir 临时 cgroup

# 后台运行时用绝对路径重定向，避免 sudo -b 改变工作目录导致输出落到 ~：
sudo ROUNDS=5 DURATION=10 THREADS=2 bash \
  "$(pwd)/run.sh" > "$(pwd)/results/full-run.out" 2>&1
```

## 测量口径

- 延迟在每个请求前后用 `CLOCK_MONOTONIC` 打点，线程内记录、结束后合并排序取分位；
  被节流冻住的时间直接计入落在窗口内的请求延迟，因此 P99/P999 对节流最敏感。
- `cpu.stat` 取运行前后快照差值：`nr_periods`（经过的调度周期数）、
  `nr_throttled`（触发节流的周期数）、`throttled_usec`（累计被限流时长）、
  `usage_usec`（实际占用 CPU 时间）。
- 每格 5 轮报告中位数；数值只对同核数、同 CFS period 的环境成立，
  换到更多核或调过 period 的环境需要重跑。
