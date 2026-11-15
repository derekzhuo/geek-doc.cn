# cgroup v2 memory.high / memory.max 回收、PSI 与 OOM 对照实验

**对应教程**：https://geek-doc.cn/concepts/container/linux-cgroup-v2-memory-max-reclaim-psi.html （随站点发布生效）

在 2 vCPU / 8 GB 云主机（Ubuntu 22.04，内核 5.15，cgroup v2 统一挂载）上用同一份内存触摸程序，
对照四种内存限制配置下的行为差异：软限 `memory.high` 的节流回收、硬限 `memory.max` 加 swap 的换出、
硬限且禁 swap 时的 cgroup OOM kill，以及各档的 PSI 内存压力累计量。

| 相位 | memory.high | memory.max | memory.swap.max | 结果 |
|---|---|---|---|---|
| A 基线 | max | max | max | 500 MiB 正常跑完 |
| B 软限 | 300 MiB | max | max | 存活，`high` 事件 1098 次，PSI total 152214 µs |
| C 硬限+swap | max | 300 MiB | max | 存活，`max` 事件 1097 次，PSI total 91484 µs |
| D 硬限禁swap | max | 300 MiB | 0 | exit=137，`oom_kill=1`，dmesg 记录 `CONSTRAINT_MEMCG` |

## 目录结构

| 文件 | 作用 |
|---|---|
| `memtouch.c` | 按 64 MiB 分块分配并逐页写入重复字节的内存触摸程序，自报 RSS 与时间戳 |
| `run-lp07.sh` | 四相位驱动：重置测试 cgroup、写入限制、采样 PSI、收集 memory.events 与 dmesg |
| `results/` | 本次完整原始输出：每相位的 before/after 快照、workload 日志、summary 与 OOM 内核记录 |

## 复现方式

需要 root、cgroup v2 统一挂载与一块可用 swap（脚本自建 2G swapfile）。

```bash
sudo bash run-lp07.sh
```

四相位分别写入 `logs-lp07/`，`memory.events` 与 `memory.pressure` 的累计值在各相位的
`*.after.txt` 里。注意限制必须在重建 cgroup 之后写入，否则随目录删除一起失效。

进程在 D 相位结束时被 OOM killer 终止属预期行为；实验结束后可自行删除
`/sys/fs/cgroup/pp-lp07` 与 `/swapfile-lp`。
