# echo — 百万 QPS TCP 高并发实战（复现手册）

> 从零到百万连接的 problem-driven 实验：先写出能跑的 TCP Echo，再在压测中逐个撞上瓶颈，每个瓶颈都是一次「诊断 → 定位 → 修复」的完整闭环。
>
> 📖 配套理论讲解见站点：[https://geek-doc.cn](https://geek-doc.cn) · 本实验页面：[https://geek-doc.cn/demos/echo/](https://geek-doc.cn/demos/echo/)

## 目录结构

本实验不是单文件 demo，而是按天推进的完整项目（`day-NN/` 为每天一个可编译运行的小程序或实验脚本）：

| 目录 | 内容 | 状态 |
|------|------|------|
| `day-01/` | 单进程阻塞 Echo（server.c / client.c），QPS 基线 ~1K | ✅ 已完成 |
| `day-02/` | epoll LT/ET、SO_REUSEPORT 多进程、压测脚本 bench.sh | ✅ 已完成 |
| `day-03/` | 长连接 vs 短连接、LT vs ET 对比、跨网络压测 | ✅ 已完成 |
| `day-04/` | FD 上限、多线程扩展、拆机实验（split-experiment-*） | ✅ 已完成 |
| `day-05/` | FD 机制深入、ulimit 链、持续自旋实验 | ✅ 已完成 |
| `day-06/` | 10K 连接验证、结果分析脚本 | ✅ 已完成 |
| `day-07/` ~ `day-30/` | 后续阶段（TCP 参数、软中断/RSS、NUMA、百万连接、短连接） | ⏳ 规划中 |
| `docs/` | 项目总纲、架构设计、各阶段小结 | ✅ 已完成 |

## 构建与运行

每个 `day-NN/` 目录自带 `Makefile`，进入对应目录执行即可（Linux 环境，需 `gcc`/`make`）：

```bash
cd echo

# Day 1：编译 + 跑通最小 Echo
cd day-01
make                      # 编译 bin/echo-server、bin/echo-client
make run-server           # 终端 1：启动服务端
make run-client           # 终端 2：客户端连接，预期输出 hello echo
make clean

# Day 2：epoll 多路复用 + 多进程压测
cd ../day-02
make                      # 编译 echo-epoll-server / echo-mp-server / echo-bench
./bench.sh                # 一键压测对比（LT vs ET、多进程分布）
```

> 各 `day-NN/README.md` 有当天的实验目标、命令与关键指标记录；`docs/` 下有项目总纲（`00-overview.md`）与架构设计（`architecture.md`）。

## 运行要求

Linux（实验涉及 `/proc`、`ulimit`、TCP 内核参数、epoll 等）。建议一台 2 核以上云主机；压测脚本可能产生大量连接，注意 FD 与端口上限。

## 实验数据

实测数据与原始输出见各 `day-NN/` 下的实验文档（如 `day-02/results_comprehensive_*/` 的完整压测输出、`day-04/fd-wall-experiment.md` 的 FD 墙实验数据），全部随代码入库，可直接复现对比。

## 配套理论

实验原理、perf/内核参数解读与原始输出分析见配套站点对应文档：

- 站点首页：https://geek-doc.cn
- 本实验页面：https://geek-doc.cn/demos/echo/

> 一句话：clone 下来按 `day-NN` 顺序推进，每个瓶颈撞上后读 `docs/` 里的阶段小结，一天一小时，30 天走完百万连接全链路。
