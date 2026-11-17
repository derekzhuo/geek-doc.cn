# CPU 隔离实测：isolcpus 能把尾延迟压下去多少

**对应教程**：https://geek-doc.cn/concepts/process/linux-cpu-isolation-isolcpus-nohz.html （随站点发布生效）

在 2 vCPU/8 GiB 的 KVM 云主机（Intel Xeon Platinum 8374C，Ubuntu 22.04，内核 5.15.0-190）上，
用双管单向 ping-pong 微基准测量线程唤醒/调度往返延迟的分布，对照默认内核与
`isolcpus=1` 启动参数下的 p50/p99/p999/最大值，并在 CPU0 注入忙等噪声检验隔离核的抗干扰能力。

## 微基准原理

`iso_lat.c` 建两条单向管道（A→B、B→A）：线程 A 写一个字节后阻塞读回，线程 B 读到后写回，
每轮是一次严格的跨线程往返，用 `CLOCK_MONOTONIC_RAW` 记录每轮纳秒耗时，
默认 1 万轮预热 + 20 万轮采样。两个线程用 `pthread_setaffinity_np` 钉在指定核上，
测三种配对：同核 0-0、跨核 0-1、同核 1-1。

> 早期版本用单条双向管道时，线程可能读回自己写入的字节，协议错位会让结果失真
> （表现为偶发卡死、跨核 p50 异常偏低）。本版本用两条单向管道从机制上杜绝该问题，
> 复现时不要改回单管。

## 四种场景

| 场景 | 内核启动参数 | CPU0 忙等噪声 | 日志 |
|---|---|---|---|
| default | 默认 | 无 | baseline.log |
| isolated | 追加 `isolcpus=1` | 无 | isolated.log |
| default+noise | 默认 | 有（busy.c 钉 CPU0） | noise-baseline.log |
| isolated+noise | 追加 `isolcpus=1` | 有 | noise-isolated.log |

每场景三个配对各跑 3 次，每次 20 万轮；`run-iso.sh` 与 `run-noise.sh` 还会保存
每轮前后的 `/proc/interrupts` 快照，并对 1-1 配对跑一次 `perf stat`。

## 复现步骤

```bash
gcc -O2 -pthread iso_lat.c -o iso_lat
gcc -O2 busy.c -o busy
sudo ./run-iso.sh baseline          # 默认内核先测

# 追加隔离参数（Ubuntu/Debian GRUB）
sudo cp /etc/default/grub /etc/default/grub.bak
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/&isolcpus=1 /' /etc/default/grub
sudo update-grub && sudo reboot
cat /sys/devices/system/cpu/isolated   # 重启后应输出 1
sudo ./run-iso.sh isolated
sudo ./run-noise.sh isolated           # 带 CPU0 噪声

# 回滚：恢复 grub.bak、update-grub、reboot，再跑 baseline 噪声对照
sudo ./run-noise.sh baseline
```

## 关键结果（单位 ns，三次重复的代表值）

无噪声时，同核配对 p999 约 6–8 μs，跨核 0-1 约 32–45 μs（跨核唤醒要走 IPI）；
`isolcpus=1` 单独使用只带来温和改善。真正的差距出现在 CPU0 被忙等占满时：

| 配对 | 指标 | 默认内核+噪声 | 隔离+噪声 |
|---|---|---|---|
| 跨核 0-1（B 在 CPU1） | p999 | 5.4–6.4 ms | 2.1–2.4 ms |
| 同核 1-1（都在 CPU1） | 最大值 | 179–855 μs | 65–70 μs |
| 同核 0-0（都在噪声核） | p999 | 7–9 μs | 12–13 μs（不受保护，符合预期） |

## nohz_full 为什么缺席

本机 `/boot/config-5.15.0-190-generic` 明确标注 `# CONFIG_NO_HZ_FULL is not set`，
Ubuntu 通用云内核没有编译无滴答完整能力，`nohz_full=` 参数不可用，`rcu_nocbs` 同理。
因此本实验只覆盖通用性最好的 `isolcpus`：它把 CPU1 移出 CFS 常规负载均衡，
普通任务不会被调度到该核，但硬中断、RCU 回调、计时 tick 仍会打断它——
这正是隔离后仍有毫秒级最大值的原因。需要完整无滴答要换编译了 `CONFIG_NO_HZ_FULL`
的内核（如 lowlatency/RT 流派），这属于选型前提而非参数调优。

## 适用边界

- 2 vCPU 虚拟机的核数太少，隔离一个核后仅剩一个 housekeeping 核，生产机应保留足够管家核。
- 微基准用管道阻塞唤醒代表典型事件驱动线程，计算密集型独立任务的隔离收益主要体现为
  调度迁移归零（`perf stat` 的 cpu-migrations 实测为 2，仅启动期残留），与本文尾延迟口径不同。
- GRUB 修改有启动失败风险，远程机器操作前确保有控制台兜底；实验结束记得恢复 grub.bak。
