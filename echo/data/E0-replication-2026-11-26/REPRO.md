# E0 独立复核：同一代码在不同 32C64G 机型上的吞吐（2026-11-26）

## 结论

本次使用未修改的 `echo/day-04/echo-mt-server.c` 与 `echo/day-03/echo-kp-bench.c`，在两台全新上海 SPOTPAID 32C64G 实例上重新测量，不沿用 2026-10-14 的结果。

- 应用端整轮 QPS：8 线程两轮为 **159,865.6 / 119,168.3 req/s**；32 线程两轮为 **444,002.7 / 459,246.3 req/s**。
- 32 线程长稳态完成 **64,000,000** 请求，零失败，`elapsed=150.469s`，整轮 **425,337.1 req/s**；其中连续 60 秒对齐热相的服务端 `sar` 为 **553,490.5 rx PPS / 553,490.7 tx PPS**。
- 热相网卡收发包基本 1:1，`ethtool` 队列包数差分与 `sar` 同量级。整轮 QPS 低于热相 PPS 的主要可见原因是建连爬升时间计入整轮，不应把热相 PPS 直接写成应用整轮 QPS。
- 本次未复现历史 2.4M QPS；新机型、内核和实测条件不同，结果只代表本次环境，不能据此反推历史数据造假或推算其他机型上限。

## 环境与代码

- 服务端和客户端：各 32 vCPU / 64GB，Intel Xeon 6983P-C，32 个逻辑 CPU。
- 系统：Ubuntu 22.04.5 LTS，Linux 5.15.0-190-generic。
- 网络：同 VPC 私网，`virtio_net`，服务端 `eth0` 为 32 combined 队列。
- 服务端：`./echo-mt-server 9988 32 lt on`。
- 编译参数：`gcc -O2 -g -Wall -Wextra -lpthread`。
- 源码哈希见 `SOURCE_SHA256.txt`；CPU、网卡和系统原始信息见 `environment/`。

## 复现命令

服务端编译并运行：

```bash
gcc -O2 -g -Wall -Wextra -o echo-mt-server echo-mt-server.c -lpthread
./echo-mt-server 9988 32 lt on
```

客户端编译后，按 `commands/` 中每个轮次的原样命令运行。长稳态为：

```bash
gcc -O2 -g -Wall -Wextra -o echo-kp-bench echo-kp-bench.c -lpthread
./echo-kp-bench <vpc-server-ip> 9988 32 2000000 --mode long
```

服务端观测脚本为 `scripts/observe.sh`。它轮询 `/proc/net/dev` 的收发包计数列，在包速率超过 30K PPS 后保存 ethtool 与 softirq 前快照，同时启动 sar、mpstat 和可选 perf，结束后保存后快照。存档的 `sar/*-trigger.txt` 来自最初误取字节列的版本，其中 `trigger_pps` 实际记录的是 bytes/s；这里保留原始记录，复现脚本已改为包计数列。热相有效性不由该触发值判断，而以 `sar` 逐秒记录为准：

```bash
bash observe.sh steady32-long 60 30
```

脚本参数依次为轮次名、 sar/mpstat 采样秒数、perf 采样秒数。perf 原始文件和报告已保留；报告需要 root 重新生成时可用：

```bash
sudo perf report -f --stdio -i perf.data --percent-limit 0.5
```

## 应用吞吐与热相 PPS

下表的 QPS、elapsed 和请求数直接来自客户端原始输出；PPS 来自服务端对齐热相的 `sar -n DEV 1` 平均值。短阶梯每线程执行 1,000,000 rounds，8/32 线程复测相同。

| 轮次 | 连接/线程 | 请求数 | elapsed (s) | 应用整轮 QPS | sar rx PPS | sar tx PPS |
|---|---:|---:|---:|---:|---:|---:|
| t1 | 1 | 1,000,000 | 48.009 | 20,829.3 | 21,293.7 | 21,293.5 |
| t2 | 2 | 2,000,000 | 49.207 | 40,645.0 | 40,557.2 | 40,557.2 |
| t4 | 4 | 4,000,000 | 49.729 | 80,435.8 | 82,149.6 | 82,149.7 |
| t8-r1 | 8 | 8,000,000 | 50.042 | 159,865.6 | 162,820.7 | 162,821.0 |
| t8-r2 | 8 | 8,000,000 | 67.132 | 119,168.3 | 153,024.6 | 153,024.4 |
| t16 | 16 | 16,000,000 | 62.358 | 256,584.4 | 316,949.2 | 316,949.0 |
| t32-r1 | 32 | 32,000,000 | 72.072 | 444,002.7 | 537,006.6 | 537,006.3 |
| t32-r2 | 32 | 32,000,000 | 69.679 | 459,246.3 | 559,468.4 | 559,468.5 |
| steady32-long | 32 | 64,000,000 | 150.469 | 425,337.1 | 553,490.5 | 553,490.7 |

`t8-r2` 与 `t32-r*` 的整轮 QPS 和热相 PPS 差距比 `t8-r1` 大，说明连接建立阶段的占比不能忽略。长稳态的 60 秒观测窗内每一秒均有持续流量，不存在把空闲平均值当热相的情况。

### 突发与稳态

| 轮次 | 请求数 | elapsed (s) | QPS |
|---|---:|---:|---:|
| burst32-r100 | 3,200 | 0.009 | 351,081.3 |
| burst32-r1000 | 32,000 | 0.085 | 377,288.6 |
| burst32-r10000 | 320,000 | 0.721 | 443,846.9 |
| steady32-long | 64,000,000 | 150.469 | 425,337.1 |

短突发低于本次持续热相约 553K PPS，不能拿短窗口外推稳态；长稳态整轮值又包含爬升，两个口径应并列呈现。

## 网卡硬件计数对账

`ethtool -S eth0` 的所有 `rx_queue_N_packets`、`tx_queue_N_packets` 分别求和再做前后差分。10 秒短窗内，ethtool 差分换算的 PPS 与 sar 比值约为 **1.0003–1.0004**；长稳态 60 秒窗为：

- NIC rx delta：**33,733,602**；NIC tx delta：**33,733,602**。
- 按 60 秒折算：**562,226.7 rx/s**，与 sar **553,490.5 rx/s** 相差约 **1.58%**。
- 这 1.58% 来自 PPS 触发、ethtool 快照和 sar 整秒窗口并非完全同一边界；两者同量级且 rx/tx 差分完全一致。
- 每个请求对应一个入向数据包和一个出向响应包，TCP 建连与纯 ACK 使总包数可以略高于应用请求数。因此不能用 `QPS × 60` 代替实际窗口内请求数，也不能把双向 PPS 相加后当作请求速率。

原始前后快照在 `eth/`，逐秒 PPS 在 `sar/`。

## CPU、softirq 与 perf

长稳态 60 秒 `mpstat` 平均值：`%usr=0.75`、`%sys=8.25`、`%soft=6.32`、`%idle=84.66`。softirq 前后差分的 NET_RX 总量为 **51,338,989**；CPU15、CPU4、CPU19 分列前三，约 2.83M、2.72M、2.54M，CPU1/3/24/27/30 接近零，说明网络中断负载并未均匀铺满 32 个逻辑 CPU。NET_RX 次数高于同窗口 NIC 收包数并不表示每个包只触发一次 softirq；NAPI 轮询唤醒次数与批处理包数不是同一计数口径。

30 秒热相 perf 共 **191,040** 个样本，`Total Lost Samples: 0`：

- `swapper` 约 **90.27%**，其中 `mwait_idle` self 约 **81.15%**，与 mpstat 的高 idle 一致。
- `echo-mt-server` 的系统调用入口约 **8.78%**；`write` 调用链约占 **3.83%**，依次进入 `ksys_write`、`vfs_write`、`tcp_sendmsg`。
- `epoll_wait` 约 **2.65%**、`read` 约 **2.02%**。
- 接收侧 `net_rx_action` 约 **4.60%**、`virtnet_poll` 约 **4.06%**、`tcp_v4_rcv` 约 **2.51%**。

因此本次主要时间花在系统调用、TCP 收发和 virtio_net 软中断路径，而不是用户态 echo 逻辑；大量 idle 说明不能简单用“32 核已打满”解释吞吐上限。

## 文件索引

- `bench/`：应用原始 stdout/stderr，含请求数、失败数、elapsed、QPS 和延迟。
- `commands/`：逐轮原样命令，地址使用占位符。
- `sar/`：逐秒网络 PPS、错误输出和 PPS 触发记录。
- `eth/`：ethtool 前后原始计数。
- `cpu/`：mpstat 逐 CPU 原始输出。
- `softirqs/`：`/proc/softirqs` 前后快照。
- `perf/`：perf.data、record 输出和符号化 report；`steady32-long` 是主结论窗口。
- `environment/`：服务端与客户端 CPU、NIC 原始信息。

所有文本中的公网地址、私网地址和实例 ID 均已替换为 `<server>`、`<client>`、`<vpc-server-ip>`、`<vpc-client-ip>`、`ins-<已销毁实例ID>`。两台临时实例及其 EIP 已在证据回传后销毁。
