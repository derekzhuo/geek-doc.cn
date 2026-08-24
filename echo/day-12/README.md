# Day 12: 网卡 RSS 与 IRQ 绑定 (NIC RSS & IRQ Binding)

> 所属阶段：阶段 4 — CPU 与软中断

## 今日目标

开启网卡多队列 RSS，将 IRQ 中断绑定到不同 CPU，让 8 个核一起来处理网络流量。

## 前置状态

- 所有网络中断在 CPU0，%soft = 80%

## 原理：RSS 如何工作

RSS（Receive-Side Scaling，接收端缩放）通过数据包的**哈希值**（源 IP、源端口、目的 IP、目的端口）将流量分配到不同的接收队列。每个队列有独立的 IRQ，可以绑定到不同的 CPU。

```bash
原来:
  网卡 → 1 个队列 → IRQ → CPU0 → 软中断 → CPU0

开启 RSS 后:
  网卡 → 8 个队列 → 8 个 IRQ → CPU0-7 → 软中断均匀分布
```

## 要做什么

### 1. 查看网卡队列数

```bash
ethtool -l eth0
# 看 "Combined" Queues 的数量，设置到最大值
```

### 2. 设置 RSS 队列数

```bash
ethtool -L eth0 combined 8
```

### 3. 关闭不必要的 Offload

对于 echo 场景，网卡 Offload（GRO/LRO/TSO/GSO）反而增加延迟和 CPU 开销：

```bash
ethtool -K eth0 gro off lro off tso off gso off
```

### 4. 设置 IRQ 亲和性

```bash
# 查看网卡对应的 IRQ 号
ls /proc/irq/ | while read irq; do
    grep -l eth0 /proc/irq/$irq/* 2>/dev/null && echo "IRQ $irq → eth0"
done

# 手动绑定: 每个 IRQ 绑定一个 CPU
echo 1 > /proc/irq/<IRQ0>/smp_affinity    # 绑定到 CPU0
echo 2 > /proc/irq/<IRQ1>/smp_affinity    # 绑定到 CPU1
echo 4 > /proc/irq/<IRQ2>/smp_affinity    # 绑定到 CPU2
# ... (bitmask: 2^cpu)
```

### 5. 编写脚本固化

```bash
# scripts/04-nic-tuning.sh
```

## 验证

```bash
# 重新压测
./echo-client --conn 50000 --mode long --rate 1 --duration 60

# 再次观测
mpstat -P ALL 1
# 期望: 8 个核的 %soft 基本均匀
cat /proc/softirqs
# 期望: NET_RX 均匀分布到 8 个核
```

## 关键指标记录

| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| 网卡队列数 | 1 | 8 |
| CPU0 %soft | ~80% | ~10% |
| 各核 %soft 均衡度 | 极度不均 | 基本均匀 |
| 总 PPS 上限 | 单核受限 | 大幅提升 |

> **一句话总结**：RSS + IRQ 绑定是把"单核瓶颈"变成"多核并行"的关键一步——不是让单个核更快，而是让 8 个核一起干。这是网络密集型服务在打开 NUMA 话题之前的最后一个"大局观"优化。

