# Day 8: TCP 缓冲区与吞吐调优 (TCP Buffer Sizing & Throughput)

> 所属阶段：阶段 3 — TCP 内核参数

## 今日目标

端口范围解决后，连接能建起来了，但加业务流量时发现吞吐上不去。今天定位 TCP 缓冲区瓶颈。

## 前置状态

- 3 万连接稳定
- 每连接空闲，尚未加业务流量

## 撞上了什么

```bash
# 给 1 万活跃连接发送 4KB 消息
./echo-client --conn 30000 --mode long &
sleep 5
# 启动 1 万连接上的收发
./echo-client --conn 10000 --mode long --msg-size 4096 --rate 100

# 观测 QPS 远低于预期
sar -n DEV 1
# 带宽只跑到 ~200MB/s，远低于 9Gbps 网卡上限
```

## 诊断步骤

```bash
# 1. 查看 TCP 读写缓冲区
cat /proc/sys/net/ipv4/tcp_rmem
# 4096    87380   6291456
# min=4KB  default=87KB  max=6MB

cat /proc/sys/net/ipv4/tcp_wmem
# 4096    16384   4194304
# min=4KB  default=16KB  max=4MB

# 2. 查看 TCP 内存
cat /proc/sys/net/ipv4/tcp_mem
# 待记录（系统级 TCP 内存压力阈值，三个值: low/pressure/high）

# 3. 观测是否因缓冲区小导致写阻塞
# 默认 default=87KB 对于 4KB 消息来说偏小
# 高速率下会频繁触发缓冲区满 → 应用层 write() 阻塞
```

## 修复

```bash
# 增大读写缓冲区
echo "4096    65536   16777216" > /proc/sys/net/ipv4/tcp_rmem
echo "4096    65536   16777216" > /proc/sys/net/ipv4/tcp_wmem

# 增大系统级 TCP 内存预算（约 32GB 的 20% = 6GB+）
# 单位是 page，按 4KB page 算
echo "786432 1048576 1572864" > /proc/sys/net/ipv4/tcp_mem
```

## 重新测试

```bash
./echo-client --conn 10000 --mode long --msg-size 4096 --rate 100
sar -n DEV 1
# 带宽应该显著提升
```

## 关键指标记录

| 指标 | 修复前 | 修复后 |
|------|--------|--------|
| `tcp_rmem` default | 87380 | 65536 |
| `tcp_rmem` max | 6291456 | 16777216 |
| `tcp_wmem` max | 4194304 | 16777216 |
| 1 万连接吞吐 | 待记录 | 待记录 |

> **一句话总结**：TCP 读写缓冲区是吞吐的"蓄水池"——太小则频繁阻塞 write()，太大则浪费内存。16MB max 在 32GB 机器上足够支撑数十万连接的突发流量。
