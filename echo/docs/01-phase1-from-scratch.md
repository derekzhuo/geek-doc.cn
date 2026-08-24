# 阶段 1：从零写出 Echo 服务（Day 1-3）

> **阶段目标**：在没有预设任何系统优化的裸机上，从零用 C 语言写出一个多进程 + epoll + SO_REUSEPORT 的 TCP Echo 服务，编译通过，localhost 测试通过，部署到云主机实现远程收发。

## 此刻的状态

一台 CentOS Stream 9 云主机，只装了 gcc 和 make。**不做任何系统调优**——ulimit 保持默认 1024，TCP 参数保持默认，不配置网卡。

## 每日概览

| 天 | 主题 | 关键操作 | 产出 |
|:--:|------|------|------|
| Day 1 | [TCP Echo 服务从零编码](/demos/echo/day-01/) · [深入原理](/demos/echo/day-01/deep-dive.md) | C 语言 socket/bind/listen/accept/epoll 编程，单进程版先跑通 | `echo-server.c`、`echo-client.c` |
| Day 2 | [本地测试与基线验证](/demos/echo/day-02/) | epoll EPOLLET + 多进程 SO_REUSEPORT，100 并发基准测试 | `echo-epoll-server.c`、`echo-mp-server.c`、`echo-bench.c` |
| Day 3 | [Keep-Alive 长连接验证](/demos/echo/day-03/) | 短连接 vs 长连接 QPS 对比、连接数扫描、strace 验证 close() 消除、远程部署（可选） | `echo-kp-bench.c` + 数据表 |

## 完工验证清单

- [ ] echo-server 编译通过，无 warning
- [ ] echo-client 发送 "hello"，server 原样返回 "hello"
- [ ] 100 并发连接收发正常，无丢包
- [ ] localhost vs 远程延迟差异可量化
- [ ] 了解每个系统调用的作用和返回值含义

> **一句话总结**：阶段 1 是纯编码——在零优化的裸机上写出能跑的 Echo 服务，为后续撞墙做准备。此刻 ulimit 还是 1024，这是故意留下的第一个"雷"。
