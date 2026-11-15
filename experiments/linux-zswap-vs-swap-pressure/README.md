# zswap 开/关 × 可压缩/不可压缩负载的四格对照实验

**对应教程**：https://geek-doc.cn/concepts/memory/linux-zswap-vs-swap-pressure.html （随站点发布生效）

在 2 vCPU / 8 GB 云主机（Ubuntu 22.04，内核 5.15，zswap 为 lzo + zbud）上把内存限制为 1200 MiB、
换出额度 1200 MiB，用 1800 MiB 工作集压出强制回收，对照 zswap 开关与页面内容可压缩性
对换出行为、PSI 停顿和耗时的影响。

| 格 | zswap | 负载 | 耗时(s) | pswpout 增量(页) | PSI some 增量(µs) | 峰值 swap.current | 峰值 zswap stored(页) |
|---|---|---|---|---|---|---|---|
| zY-zero | 开 | 重复字节 | 1.548 | 0 | 411959 | 514326528 B | 126216 |
| zY-random | 开 | 随机 | 1.535 | 0 | 384140 | 441384960 B | 108307 |
| zN-zero | 关 | 重复字节 | 4.065 | 162703 | 1918733 | 638689280 B | 0 |
| zN-random | 关 | 随机 | 4.071 | 161861 | 1657577 | 654331904 B | 0 |

核心结论：zswap 开启时 600 MiB 超配匿名页全部压缩进内存池，`pswpout` 全程不增长，
耗时约为裸 swap 的 38%，PSI 停顿约为 1/4～1/5。zswap 条目随进程退出即释放，
必须运行中采样，进程结束后再读 `/sys/kernel/debug/zswap/` 只剩零头。

## 目录结构

| 文件 | 作用 |
|---|---|
| `memtouch.c` | 分块内存触摸程序，zero 模式逐页写重复字节（可压缩）、random 模式写伪随机字节 |
| `run-lp19.sh` | 四格驱动：切换 zswap、重建 2G swapfile、限内存 cgroup、0.5s 采样并提取峰值 |
| `results/` | 四格的 workload 日志、运行中采样日志（sampler）、summary 与完整 master 日志 |

## 复现方式

需要 root 与 `/sys/kernel/debug/zswap/`（debugfs）。

```bash
sudo bash run-lp19.sh
```

四格依次写 `logs-lp19/`，`*.sampler.log` 是 0.5s 间隔的 memory.current /
swap.current / pswpout / zswap.stored 时间序列，summary 里的峰值由它提取。

脚本会切换全局 zswap 开关并操作 swapfile，请在实验机上运行。
