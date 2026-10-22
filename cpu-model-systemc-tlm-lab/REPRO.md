---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/cpu-model-systemc-tlm-lab/`，配套页面 https://geek-doc.cn/demos/cpu-model-systemc-tlm-lab/


# cpu-model-systemc-tlm-lab

CPU 微架构建模系列第四批（**C1–C5 SystemC 语言内核、D1–D5 TLM-2.0**，共 10 篇）共用的**自包含 C++17 实验台**。
**不依赖 SystemC 或任何外部库**：用一个文件内可读的最小实现，把文章要讲的内核/总线语义**真实跑出来**——事件队列的 evaluate/update 两阶段与 delta cycle、notify 三态、信号多驱动解析、任意位宽/定点截断、VCD 稀疏记录，以及 TLM 的 generic payload、socket、LT 阻塞 vs AT 四阶段非阻塞、时序注解、全局量子时间解耦、PEQ、乱序响应、DMI/transport_dbg 与路由器仲裁。

> 它**不是** Accellera SystemC/TLM 库的重新实现，也不替代真实库；它用最少的代码把"内核为什么这么调度、事务为什么这么握手"演示清楚，便于在没装 SystemC 的环境（如本机/CentOS7 devtoolset-10）直接编译验证。生产虚拟原型请链接 Accellera SystemC 2.3.x + TLM-2.0。

## 构建与运行

```bash
make            # g++ -O2 -std=c++17 -Wall -Wextra
./lab all       # 跑全部 10 个实验
./lab 6         # 只跑第 n 个（1..10）
```

实测环境：CentOS 7 + devtoolset-10（GCC 10.2.1），`-Wall -Wextra` 零警告。

## 实验目录

| 编号 | 文章 | 模型内容 |
|---|---|---|
| 1 | C1 仿真内核 | evaluate/update 两阶段、同一 evaluate 写不可见、零时刻 delta 环（同一时刻可有无穷多 delta） |
| 2 | C2 时间/时钟/调度 | immediate / delta / timed 三种 notify；时钟=自重装的定时通知；仿真时间与墙钟时间 |
| 3 | C3 端口/接口/通道 | 多驱动 OR 解析信号（对照 last-write-wins）、有界阻塞 FIFO 的背压计数 |
| 4 | C4 数据类型 | `sc_uint<W>` 截断回绕、`sc_int<W>` 符号扩展、`sc_fixed` 定点量化误差 |
| 5 | C5 调试/波形/结构 | VCD 只记 value-change（8 拍 4 行）、SC_REPORT 分级 verbosity |
| 6 | D1 LT vs AT | 1000 次 b_transport（1 调用/事务+延迟注解）vs 10 个在途事务四阶段流水（200fs vs 串行 2000fs） |
| 7 | D2 payload/socket | 全字段 + 扩展 trace_id、socket bind、地址解码路由、byte-enable 通路回读、DECERR |
| 8 | D3 时间解耦 | 本地时间偏移 + 全局量子：量子 200/1000/5000 → 同步点 5000/1000/200 |
| 9 | D4 AT/PEQ | PEQ 按各自延迟排序，3 事务发出序 0,1,2 → 完成序 1,2,0（乱序响应） |
| 10 | D5 DMI/dbg/路由 | 1000 次直指针 DMI 写（0 次事务调用）、transport_dbg 零仿真时间、DMI 失效回退、三主设备加权仲裁 |

## 设计原则

- **跑真语义，不背 API**：每个数字都来自事件队列或 socket 的真实控制流，而非打印假数据。
- **功能与性能两种编码都覆盖**：LT（`b_transport` + 时序注解，软件快跑）与 AT（`nb_transport` 四阶段 + PEQ，性能建模）在同一实验台对照。
- **确定性**：无随机、无外部依赖，输出可复现；数字用于讲清量纲与趋势，不代表任何具体商用工具。
- 相关的"性能/结构记账模型"（流水线/cache/一致性/NoC 等）见上一批 [`../cpu-model-core-mem-lab`](../cpu-model-core-mem-lab/)；指令集功能底座见 [`../cpu-model-isa-iss`](../cpu-model-isa-iss/)。

## 一句话总结

systemc-tlm-lab 在不安装 SystemC 的环境下用最小 C++17 实现真实跑通事件调度、delta cycle、LT 阻塞与 AT 四相握手、全局量子、PEQ 和 DMI，用对照实验讲清内核调度与 TLM 事务语义。
