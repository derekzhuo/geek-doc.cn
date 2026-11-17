# 单队列网卡软中断分流实测：RSS / RPS / RFS 四组对照

**对应教程**：https://geek-doc.cn/concepts/network/linux-rps-rfs-xps-softirq.html （随站点发布生效）

在 2 vCPU/8 GiB 的 KVM 云主机（virtio-net，最多 2 个 combined 队列）上，用同 VPC 内网压测机打 wrk，
对照四种收包配置下软中断在两个 CPU 核上的分布、硬中断归属与吞吐差异，回答一个问题：
网卡只有一个接收队列时，内核软件分流（RPS/RFS）能把单核软中断瓶颈救回多少，代价是什么。

## 实验拓扑

| 角色 | 规格 | 说明 |
|---|---|---|
| 被测机 target | 2 vCPU / 8 GiB，Ubuntu 22.04，内核 5.15.0-190 | nginx 1.18.0 在 8080 端口提供 225 字节小文件 |
| 压测机 loader | 2 vCPU / 4 GiB，同 VPC 同子网，无公网 IP | wrk 4.1.0，经内网直连 target，链路 RTT 约 0.7 ms |

压测机必须与被测机在同一 VPC：经公网回环受 RTT 与丢包限制，实测只能打到百级 RPS，
无法产生软中断压力；同 VPC 内网可以稳定打出 5 万级 RPS。复现时把脚本里的内网地址
（示例为 `172.17.16.16`）替换为你自己被测机的实际内网 IP。

## 四组配置

| 组 | combined 队列 | rps_cpus | rps_sock_flow_entries | 含义 |
|---|---|---|---|---|
| g1-rss2 | 2 | 0 | 0 | 硬件 RSS 双队列，基线 |
| g2-single | 1 | 0 | 0 | 单队列，不做软件分流 |
| g3-rps | 1 | 2（交 CPU1 处理） | 0 | 单队列 + RPS 软分发 |
| g4-rfs | 1 | 2 | 32768，rps_flow_cnt=4096 | 单队列 + RPS + RFS 流表亲和 |

每组各跑两种负载，各 25 秒：keep-alive（`wrk -t2 -c128 -d25s`）与短连接
（`wrk -t2 -c64 -d25s -H "Connection: close"`）；g2/g3 另加 c256/c128 高压档复核。
采样用 `mpstat -P ALL 1 25`，前后各取一次 `/proc/interrupts` 与 `/proc/net/softnet_stat`。

## 复现步骤

```bash
# 被测机
sudo bash group.sh g1-rss2          # 切换配置，g1-rss2/g2-single/g3-rps/g4-rfs
sudo bash sample.sh g1-rss2-ka      # 25 秒 mpstat + 中断/softnet 快照
# 压测机（与被测机 SSH 免密互通后，也可直接在被测机执行 run-all.sh 全自动编排）
wrk -t2 -c128 -d25s http://<target-内网IP>:8080/
bash run-all.sh                     # 四组 x 两种负载全自动，约 4 分钟
python3 parse_results.py            # 汇总 raw/ 为 results.csv
```

## 关键结果（节选，完整数据见 results.csv 与 raw/）

短连接负载下，g2-single 的 `%soft` 为 CPU0 74.91% / CPU1 0.00%，全部硬中断也只落在 CPU0；
g3-rps 把软中断摊到 CPU0 36.39% / CPU1 55.42%，但硬中断仍在 CPU0（RPS 迁移的是软中断处理，
不是硬中断）。12 轮采样 softnet 丢包列全程为 0：本实验流量没有把单核压到丢包，
RPS 的价值是抬高软中断天花板，而不是在非饱和流量下免费提升吞吐——keep-alive 档
g2 反而比 g3/g4 高约 8%，软件分发的 IPI 与 backlog 入队有固定成本。

## 适用边界

- 结论基于 2 vCPU、virtio-net 双队列上限的云主机；物理多队列网卡与更多核数下 RSS 通常已足够，
  RPS/RFS 主要用于单队列设备、RSS 队列数少于核数或需要二次摊平的场景。
- 本次未观测到 softnet 丢包，不应外推为「单队列不会丢包」；更高 PPS 下 backlog 溢出时
  `/proc/net/softnet_stat` 第二列才会增长。
- `group.sh` 会修改队列数、rps_cpus 与 flow 表参数，复现机不要同时跑其他依赖这些配置的服务。
