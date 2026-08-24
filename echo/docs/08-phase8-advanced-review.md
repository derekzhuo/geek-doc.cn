# 阶段 8：进阶实验与全链路复盘（Day 28-30）

> ⏳ **状态：规划中**。

> **目标**：引入 L2 带计算 echo 和 L3 流式分包 echo，覆盖 CPU/网络混合瓶颈和 TCP 流式语义这两个进阶主题。最后做全链路复盘，输出故障排查决策树。

## 背景

L1 裸 echo 证明了系统能承载百万连接。现在引入业务逻辑，看看 CPU 和网络混合时会发生什么，以及 TCP 粘包/拆包问题如何处理。

## 每日概览

| 天 | 主题 | 关键操作 | 产出 |
|:--:|------|------|------|
| Day 28 | [L2 带计算 Echo](/demos/echo/day-28/) | `echo-server-compute` 引入可调 CPU 运算权重，perf 观测 IPC（Instructions Per Cycle，每周期指令数）和 LLC（Last-Level Cache，末级缓存）miss | CPU/网络混合瓶颈数据 |
| Day 29 | [L3 流式分包 Echo](/demos/echo/day-29/) | `echo-server-stream` 自定义帧协议 `[4字节长度][payload]`，处理粘包/拆包/半包 | 帧协议实现 |
| Day 30 | [全链路复盘与排查决策树](/demos/echo/day-30/) | 整理 30 天所有指标数据，绘制性能瓶颈决策树，输出最终交付物 | `performance-troubleshooting-guide.md` |

## L2 vs L1 对比

| 维度 | L1 裸 echo | L2 带计算 echo |
|------|------|------|
| CPU 时间分布 | 100% 在内核协议栈 | 用户态计算 + 内核协议栈 |
| 瓶颈位置 | 网卡/软中断/NUMA | CPU 微架构（IPC/分支/缓存） |
| perf 热点 | 几乎全是内核函数 | 用户态 `do_compute()` 占比明显 |

## L3 vs L1 对比

| 维度 | L1 裸 echo | L3 流式分包 echo |
|------|------|------|
| 数据边界 | 每次 `read()` 就是一个完整消息 | 需要帧头解析，处理粘包 |
| 缓冲区管理 | 无状态 | 每个连接维护 `conn_state_t` 缓冲区 |
| 内存开销 | per-connection kernel TCP buffer | + per-connection user buffer |

## 最终交付物

```bash
echo/
├── src/scripts/                  # 12 个一键脚本（全部可独立执行）
│   ├── 02-ulimit-setup.sh        # FD 上限
│   ├── 03-tcp-kernel-params.sh   # TCP 内核参数
│   ├── 04-nic-tuning.sh          # 网卡 RSS + IRQ
│   ├── 06-restore-all.sh         # 一键恢复全部配置
│   ├── numa-*.sh                 # NUMA 全套（4 个）
│   ├── monitor-*.sh              # 监控采集
│   └── diag-tcp.sh               # TCP 诊断
├── docs/
│   ├── performance-troubleshooting-guide.md  # 排查流程图
│   └── 30 天完整指标数据
└── bin/                          # 三层 echo 服务 + 压测工具
```

## 完工验证清单

- [ ] L2 能观测到 IPC 随计算权重增加而下降
- [ ] L3 能正确处理粘包/拆包
- [ ] 全链路一键恢复脚本可正常执行
- [ ] 排查决策树覆盖 QPS/延迟/连接/内存四大场景

> **一句话总结**：阶段 8 把三层 echo 服务串起来——L1 验证了基础设施承载能力，L2 暴露了 CPU 微架构瓶颈，L3 让你直面 TCP 流式语义的工程复杂性，最终输出一份可复用的性能排查决策树。

