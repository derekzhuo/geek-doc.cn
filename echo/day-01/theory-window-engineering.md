# 深入论述三（6/6）：双窗口协同场景、read() 拿不全数据与工程速查

> 所属 Day：[Day 1 从零编码](/demos/echo/day-01/) · 更新时间：2026-08-21（从 theory-mss-nagle-cwnd.md 拆分，内容零丢失）
> 本系列：[深入论述三索引](/demos/echo/day-01/theory-mss-nagle-cwnd.md)
> 上一篇：[5/6 cwnd 四阶段与拥塞控制算法](/demos/echo/day-01/theory-congestion-control.md)
> 下一篇：[深入论述四：read() 返回量不可预测](/demos/echo/day-01/theory-read-semantics.md)

---

## 一、双窗口协同的四种典型场景

| 场景 | cwnd vs rwnd | 实际限制 | 典型例子 | 优化方向 |
|------|:---:|------|------|------|
| **网络拥塞限制** | cwnd << rwnd | cwnd | 跨公网传输、丢包率高 | 换拥塞控制算法（BBR）、降低延迟 |
| **接收端限制** | rwnd << cwnd | rwnd | 应用层 read() 太慢、recv_buf 太小 | 调大 `tcp_rmem`、优化应用读速度 |
| **带宽延迟积限制** | cwnd ≈ BDP | BDP | 长肥管道（跨洋链路） | 增大 `tcp_init_cwnd`、调大 `tcp_wmem` |
| **零窗口悬挂** | rwnd ≈ 0 | rwnd（≈0） | 接收端进程挂死、GC 暂停 | 打开 window probe 日志、应用层心跳 |

**实际吞吐量的计算公式**：

```bash
吞吐量 = min(cwnd, rwnd) / RTT

当 cwnd 是瓶颈:
  吞吐量由拥塞控制算法决定
  需要在"多占带宽"和"不引发丢包"之间平衡

当 rwnd 是瓶颈:
  吞吐量 = recv_buf_free / RTT（≈ read()速度）
  **网络带宽再高也没用**
```

## 二、为什么 cwnd 导致 `read()` 拿不到全部数据？

回到序列图 RTT 1-3 的场景——发送端有 500KB 数据待发送：

| RTT # | cwnd | rwnd (约) | 有效窗口 | 本轮可发 | 累计到达 | 一次 `read(8192)` 拿到 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | 10 MSS | 128 KB | 14.6 KB | 14.6 KB | 14.6 KB | 8192 B（最多） |
| 2 | 20 MSS | 100 KB | 29.2 KB | 29.2 KB | 43.8 KB | 8192 B |
| 3 | 40 MSS | 50 KB | 50 KB | 50 KB | 93.8 KB | 8192 B |
| 4 | 80 MSS | 8 KB | 8 KB | 8 KB | 101.8 KB | 8192 B |
| 5 | 114 MSS | 8 KB | 8 KB | 8 KB | 109.8 KB | 8192 B |

> **结论**：`read()` 每次只能拿到 8192 字节（应用自己设的读取量上限），但发送端可能已经发了 500KB。这些数据**大部分在路上**（in flight）或者**还没发**（被 cwnd/rwnd 卡在发送端）。这就是"`read()` 返回量不确定"的最深层根源——前两个是 MSS 分段和 Nagle 合并，第三个是 cwnd 限制了在途数据量，第四个是 rwnd 因应用层读太慢而缩小。

## 三、工程参数速查

| 参数 | 默认值 | 含义 | 增大后果 | 减小后果 |
|------|--------|------|---------|---------|
| `tcp_init_cwnd` | 10 MSS (~14KB) | 初始拥塞窗口 | 首次 RTT 多发数据，适合短连接（HTTP），但可能加重突发 | 慢启动更慢，小文件传输更慢 |
| `tcp_slow_start_after_idle` | 1（开启） | 空闲超时后重置 cwnd | — | 设为 0 保持 cwnd（长连接闲置再恢复时更快） |
| `tcp_congestion_control` | cubic | 拥塞控制算法 | — | bbr 在高丢包/长肥管道更优 |
| `tcp_rmem[2]` | 默认接收缓冲区 | rwnd 上限 | 更多数据缓存在内核，延迟 ACK 策略更有效 | rwnd 容易成为瓶颈 |
| `tcp_adv_win_scale` | 1（默认） | rwnd = buf / 2^adv_win_scale | 数值越小，rwnd 越接近 buf 总大小 | 预留给开销的空间增大，实际 rwnd 减小 |

> **调参警告**：增大 `tcp_init_cwnd` 或 `tcp_rmem` 之前，先理解当前瓶颈在哪。用 `ss -ti` 看 `cwnd` / `rwnd` / `rtt` 的实际值。盲目调参最常见的后果是：cwnd 调大了 → 网络拥塞加剧 → 丢包率上升 → 实际吞吐反而下降。

> **一句话总结**：双窗口四种场景中"rwnd 瓶颈"（read() 太慢）与"零窗口悬挂"是应用层最容易撞上的两类；`read()` 拿不全数据的四层根源依次是 MSS 分段、Nagle 合并、cwnd 在途限制、rwnd 读速限制；调参前先用 `ss -ti` 确认瓶颈，避免盲目加大窗口引发拥塞。
