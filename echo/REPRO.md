# echo 实验复现手册（REPRO）

> 本手册兑现 README 的承诺：echo 项目所有实验均可在一台（或两台）Linux 机器上复现。
> 每级实验的原始数据在 `data/E*/`，逐实验的详细口径见 `data/E*/REPRO.md`。

## 代码获取

```bash
git clone https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn/echo
```

## 目录

| 实验 | 问题 | 数据 | 结论速览 |
|---|---|---|---|
| E0 基线复核 | day-04 的 253.3 万 QPS@8线程 是否真实？ | `data/E0/` | 未复现，下修为 **240 万 QPS@32线程**（长稳态 2,379,929 / 2,408,581 req/s，三口径对齐） |
| E1 百万 QPS 纵深 | QPS 随线程如何扩展？SO_REUSEPORT 与 RSS 队列各值多少？ | `data/E1/` | 32 线程 2.41M；SO_REUSEPORT 关掉后 32 线程塌到 1.38M；RSS 队列 4→32，16 线程吞吐 0.88M→1.78M |

## 环境（E0/E1 共同口径）

- 两台腾讯云 CVM，ap-shanghai，SPOTPAID 竞价，同 VPC 内网直连（实验结束即销毁）
- 服务端 32 vCPU / 64G，客户端 32 vCPU / 64G，TencentOS Server 4（内核 6.6）
- 网卡 virtio_net，32 combined 队列（`ethtool -l eth0` 可查可调）
- 编译：`gcc -O2 -g -Wall -Wextra`，无第三方依赖

## 最小复现（单机即可）

```bash
# 服务端（day-04，多线程 epoll + SO_REUSEPORT；第 4 参数 off = 共享监听对照）
gcc -O2 -o echo-mt-server day-04/echo-mt-server.c -lpthread
./echo-mt-server 9988 32 lt on

# 客户端（day-03，每连接一线程，长连接模式；输出 QPS 与 P50/P99）
gcc -O2 -o echo-kp-bench day-03/echo-kp-bench.c -lpthread
./echo-kp-bench <server-ip> 9988 1000 10000 --mode long
```

## 三口径观测（服务端另开终端）

```bash
sar -n DEV 1            # 网卡 PPS
ethtool -S eth0         # rx_queue_*_packets 前后差分 ≈ 应用请求数（1:1）
mpstat -P ALL 1         # %usr / %sys / %soft 分布
cat /proc/softirqs      # NET_RX 软中断按 CPU 分布
ethtool -L eth0 combined 4   # 调 RSS 队列数（T7 实验用；调回 32）
```

## 测量纪律（E0/E1 踩坑固化）

1. 只信**长稳态**：kp-bench 1000 线程 ramp 需数十秒，热相短于 1 秒的轮次 QPS 抖动大；结论轮次 ≥ 10M 请求。
2. 采样窗口必须落在热相内：先起压测、sleep ~12s 再 `mpstat/sar`，避免采到 ramp 或尾部 idle。
3. 腾讯云 VM 上 `ss` 连接计数不可信（E0 实测恒 0），用 ethtool 硬件计数对账。
4. 突发 < 稳态：短窗口吃不满管线，不要用突发值当峰值。
