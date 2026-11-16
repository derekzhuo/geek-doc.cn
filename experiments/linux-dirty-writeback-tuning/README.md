# 脏页回写阈值调参：vm.dirty_ratio 与 dirty_background_ratio 的实测取舍

**对应教程**：https://geek-doc.cn/concepts/storage/linux-dirty-writeback-tuning.html （随站点发布生效）

用一个自写的 C 基准程序发起 2560 MiB 缓冲写（每块 32 MiB，逐块计时，末尾一次
fsync），在三档脏页阈值下对比过程卡顿与尾部 fsync 延迟，同时用 vmstat 1 采样
flusher 回写活动（bo/wa 列）。

## 目录结构

| 文件 | 作用 |
|---|---|
| `src/dirty_bench.c` | 突发写基准：逐块写延迟 + 收尾 fsync 延迟 + 吞吐 |
| `Makefile` | 编译 `dirty_bench` |
| `run.sh` | 三档阈值（宽松/中等/收紧）串行压测，trap 保证 sysctl 复位 |
| `results/*-bench.log` | 三档基准原始输出 |
| `results/*-vmstat*.txt/log` | 三档 vmstat 采样与前后快照 |
| `results/summary.csv` | 三档关键指标汇总 |

## 复现方式

```bash
make
# 需要可写 /proc/sys/vm/dirty_ratio 与 dirty_background_ratio 的权限
sudo bash run.sh
```

## 关键结果（本机实测）

| 阈值档位（bg/ratio） | 逐块 p50 | 逐块最大 | >100ms 块数 | 收尾 fsync | 吞吐 |
|---|---|---|---|---|---|
| 宽松 10/20 | 21.3 ms | 673.9 ms | 30 | 8096 ms | 152.5 MiB/s |
| 中等 5/10 | 192.6 ms | 602.7 ms | 52 | 4232 ms | 153.1 MiB/s |
| 收紧 0/5 | 211.9 ms | 499.1 ms | 62 | 1942 ms | 153.0 MiB/s |

三档总吞吐几乎相同（都被云盘 QoS 压在约 153 MiB/s），差别在延迟分布：
宽松阈值让写入过程大部分时间很快、卡顿少，但把脏页账攒到最后，fsync 尾部
超过 8 秒；收紧阈值把回写压力平摊到全过程，单块变慢、慢块变多，fsync 降到
约 1.9 秒。调参是在「过程抖动」与「尾部延迟」之间搬移，不是提高带宽。

## 测量口径

- 每档实验前记录 vmstat 与 sysctl 快照，结束后 trap 复位，避免污染后续实验；
- vmstat 的 bo（每秒块设备写出）峰值 23–25 万块/s、wa（IO 等待占比）峰值
  96–98%，证明三档都把磁盘压到饱和，吞吐差异不是设备空闲造成的；
- 云盘 QoS 上限决定了三档吞吐趋同，物理 NVMe 上趋势仍在、具体数值会不同。
