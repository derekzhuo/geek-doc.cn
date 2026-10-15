# E1 百万 QPS 纵深：吞吐-线程曲线、SO_REUSEPORT 与 RSS（2026-10-16）

> 目的：在 E0 已坐实 240 万 QPS@32线程 的基础上，回答三个问题——
> ① QPS 随线程数如何扩展？② SO_REUSEPORT 到底值多少？③ RSS 队列数是不是第一瓶颈？

## 环境

- 两台腾讯云 CVM（ap-shanghai，SPOTPAID 竞价，同 VPC 内网直连）：
  - 服务端：S9.8XLARGE64，32 vCPU / 64G，TencentOS Server 4（内核 6.6.117），virtio_net 32 combined 队列
  - 客户端：S9.8XLARGE64，32 vCPU / 64G
- 代码：`day-04/echo-mt-server.c`（E1 新增第 4 参数 `reuseport on|off`，off = 所有线程共享一个监听 socket 的惊群对照）+ `day-03/echo-kp-bench.c`，与 E0 同一套
- 实例已在数据回传确认完整后**当场销毁**（DescribeInstances TotalCount=0 确认）

## T6 线程 × SO_REUSEPORT 矩阵（1000 连接 × 10000 rounds，每点 warm+run 两轮）

服务端 `./echo-mt-server 9988 <T> lt <on|off>`，客户端 `./echo-kp-bench <ip> 9988 1000 10000 --mode long`。

| 线程 | reuseport=on QPS | reuseport=off QPS | on 的 P50/P99 (μs) | off 的 P50/P99 (μs) |
|--:|--:|--:|--:|--:|
| 1 | 181,138 | —（等价 on） | 5513 / 5643 | — |
| 2 | 344,249 | 342,182 | 2690 / 3008 | 2791 / 3031 |
| 4 | 664,140 | 677,766 | 1448 / 2205 | 1425 / 2158 |
| 8 | 1,067,200 | 1,129,384 | 716 / 1354 | 728 / 1238 |
| 16 | 1,934,013 | 1,978,692 | 427 / 685 | 420 / 680 |
| **32** | **2,300,853** | **1,345,389** | **254 / 938** | **558 / 1661** |

读法：

- 1→16 线程近似线性（181k → 1.93M，10.7×），32 线程 2.30M 开始弯曲（内核协议栈成本凸显）。
- **≤16 线程时 SO_REUSEPORT 开关无差异**（连接建立是长连接一次性成本，accept 争用不显性）。
- **32 线程时关 SO_REUSEPORT 吞吐塌 42%**（2.30M→1.35M），P50 延迟 254→558μs 翻倍——32 个 worker 在同一个监听 socket 上惊群，accept 成串行点。

补充长稳态验证（1000 连接 × 60000 rounds = 60M 请求）：t32-rp1 = **2,409,601 req/s**，t32-rp0 = 1,382,418 req/s，与矩阵一致。

## T7 RSS 队列数扫描（16 线程、reuseport=on、60M 请求/点）

`ethtool -L eth0 combined <N>` 调队列数，每点同时采 `mpstat -P ALL`（热相窗口）与 `/proc/softirqs` 差分：

| combined 队列 | QPS | NET_RX 软中断分布 | 收包 CPU 状态 |
|--:|--:|---|---|
| 4 | 878,860 | 仅 4 个 CPU 有量，top CPU 占 26% | **4 个核 %soft ≈ 100% 打满** |
| 8 | 1,260,147 | 8 个 CPU，top 占 14% | 8 个核 %soft ≈ 64-71% |
| 32 | 1,776,502 | 32 个 CPU 均匀，top 占 3% | top 核 %soft ≈ 28% |

读法：**队列数就是收包路径的并发度上限**。4 队列时 16 个 worker 线程再闲也没用——包只能由 4 个 CPU 收，softirq 打满即天花板；队列拉到 32，软中断摊开，吞吐翻倍。

默认 32 队列下 8/32 线程各点的 `/proc/softirqs` 差分均显示 NET_RX 均匀散布全部 32 核（top CPU 仅 3-4%），说明 virtio 多队列 + RSS 哈希（按四元组）开箱即用，无需手工 IRQ 绑定。

## 三口径对齐（抽验，全部 1:1）

| 点 | 应用请求数 | NIC rx_packets 差分（ethtool -S） |
|---|---:|---:|
| t8-rp1 | 30,000,000 | 30,005,275 |
| t32-rp1 | 30,000,000 | 30,005,274 |
| t32-rp0 | 30,000,000 | 30,005,238 |
| q4/q8/q32-t16 | 30,000,000 | 30,005,28x |

多出的 ~5k 包为 TCP 建连/挥手开销。`sar -n DEV` 热相峰值：t32-rp1 3.56M pps（rx+tx，GRO 聚批后低于 2×QPS）。

## T8 瓶颈归因（本机本负载的第一瓶颈）

热相 mpstat（t32-rp1，60M 请求窗口均值）：`%usr=3.3 %sys=38.5 %soft=21.8 %idle=36.4`。

- 应用本身几乎不花 CPU（%usr 3.3%），**60% 的 CPU 时间在内核态**（%sys 系统调用路径 + %soft 协议栈软中断）。
- 32 核 idle 仍 36%：跑 240 万 echo/s 时单机没有真正打满，弯曲段来自内核锁/调度/缓存行乒乓等扩展性损耗，而非 CPU 算力耗尽。
- 收包侧软中断均匀摊开（RSS 32 队列默认就位），**软中断不均衡不是本机瓶颈；共享 accept（无 SO_REUSEPORT）才是 32 线程第一瓶颈**（-42%）。

## 数据清单

- `summary.csv`：全部 35 轮 QPS/延迟汇总（机器可读）
- `bench/`：矩阵各点 kp-bench 原始输出（warm/run 两轮）+ 长稳态（`*_long.txt` / `*_long2.txt`）
- `cpu/`：各点 mpstat -P ALL 采样（`mp_*` 矩阵粗采样，`mpB_*` 热相精采样）
- `misc/`：`/proc/interrupts`、`/proc/softirqs`、`ethtool -S` 前后快照（成对）、sar 采样、NIC 能力（nic_caps.txt）
- 本批无截图（全文本采集），shots 件豁免（同 E0 口径）

所有文本已过 `sanitize-secrets.mjs --check`（IP/实例 ID 全部占位化）。
