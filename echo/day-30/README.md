# Day 30: 全链路复盘与排查决策树 (Full Review & Troubleshooting Decision Tree)

> 所属阶段：阶段 8 — 进阶与复盘

## 今日目标

汇总 30 天所有数据，绘制性能瓶颈决策树，输出最终交付物。

## 30 天回顾

| 阶段 | 天数 | 撞上的问题 | 怎么解决的 |
|------|:--:|------|------|
| 1. 写出 Echo | Day 1-3 | TCP socket 编程 | 从零编码 |
| 2. 多线程扩展与 FD 上限 | Day 4-6 | 单线程 epoll 触顶；FD 预置未触发 | thread-per-core + SO_REUSEPORT |
| 3. TCP 参数 | Day 7-9 | 建连超时、端口不够 | ip_local_port_range、somaxconn |
| 4. CPU/软中断 | Day 10-12 | 单 CPU 打满 | 网卡 RSS + IRQ 绑定 |
| 5. NUMA | Day 13-16 | 跨节点延迟不一致 | 双 NUMA 拆分 + 就近原则 |
| 6. 百万连接 | Day 17-23 | 逐级爬升验证 | 之前所有优化的叠加验证 |
| 7. 短连接 | Day 24-27 | TIME_WAIT/端口/SYN | tw_reuse、端口范围、syn_backlog |
| 8. 进阶 | Day 28-30 | L2/L3 echo | 计算瓶颈、流式帧协议 |

## 性能瓶颈决策树

```bash
性能有问题
├── QPS/吞吐不够？
│   ├── %soft 高？ → 检查中断绑定 → RSS 多队列
│   ├── %usr 高？ → perf top 找热点 → 优化代码
│   ├── %iowait 高？ → iostat 查磁盘 → 不是 echo 场景
│   └── IPC 低？ → perf stat 查微架构 → L2 场景
├── 延迟高？
│   ├── P99 >> P50？ → 尾延迟 → NUMA 错配或调度抖动
│   ├── 延迟正比连接数？ → 队列深度 → 降连接数
│   └── 延迟比较稳定？ → 网络 RTT 下限 → 无解
├── 连接上不去？
│   ├── accept() 返回 -1？ → errno 是什么？
│   │   ├── EMFILE → FD 限制 → ulimit -n
│   │   └── 其他 → dmesg 查看
│   ├── connect() 超时？ → SYN 队列溢出 → somaxconn
│   ├── EADDRNOTAVAIL？ → 端口耗尽 → ip_local_port_range
│   └── 内存不足？ → free -h → 单连接内存 × 目标数 > RAM
└── 短连接特别慢？
    ├── TIME_WAIT 堆积？ → ss -s → tcp_tw_reuse
    ├── 端口耗尽？ → EADDRNOTAVAIL → 扩大端口范围
    └── SYN 丢包？ → netstat -s → tcp_max_syn_backlog
```

## 最终交付物清单

- [ ] 全链路一键恢复脚本：`bash scripts/06-restore-all.sh`
- [ ] NUMA 全套脚本（4 个）：bind/split/benchmark/check
- [ ] TCP 诊断工具：`diag-tcp.sh`
- [ ] 性能排查流程图（上述决策树）
- [ ] 30 天完整指标数据附录

> **一句话总结**：30 天，从 `gcc hello.c` 到百万连接——每个参数都亲眼见过"不改会怎样"，每个瓶颈都是亲手诊断、定位、修复的。这条路走完，你不只是知道"ulimit -n 要调大"，而是知道"不调大时第几个连接会崩溃、崩溃的信息是什么、怎么自己找到根因"。

