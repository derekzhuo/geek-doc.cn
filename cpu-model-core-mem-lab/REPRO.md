---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/cpu-model-core-mem-lab/`，配套页面 https://geek-doc.cn/demos/cpu-model-core-mem-lab/


# cpu-model-core-mem-lab

CPU 微架构建模系列第三批（**A3 / A4 / A5、B1–B5、E2 / E3**，共 10 篇）共用的**自包含 C++17 实验台**。
不依赖 SystemC 或任何外部库，一个 `main.cpp` 内含 10 个相互独立的**参数化周期记账模型**，与文章一一对应。

## 构建与运行

```bash
make            # g++ -O2 -std=c++17 -Wall -Wextra
./lab all       # 跑全部 10 个实验
./lab 1         # 只跑第 n 个实验（1..10）
```

实测环境：CentOS 7 + devtoolset-10（GCC 10.2.1），`-Wall -Wextra` 零警告。

## 实验目录

| 编号 | 文章 | 模型内容 |
|---|---|---|
| 1 | A3 流水线建模 | 顺序记分牌：发射资源表 + RAW 依赖就绪时间 + 控制冒险；前递开关、load-use 延迟、流水线深度（误预测惩罚）扫参 |
| 2 | A4 分支预测建模 | bimodal-1bit / bimodal-2bit / gshare 饱和计数器 + BTB；误预测率 × 流水线深度折算前端 CPI |
| 3 | A5 乱序执行建模 | 顺序重命名 + ROB/发射窗口 + 发射宽度；32 条独立 miss 链，展示 MLP 随窗口增长 |
| 4 | B1 Cache 建模 | 组相联 LRU，冷/容量/冲突 3C 分类，AMAT 随容量-相联度扫描 |
| 5 | B2 一致性协议建模 | 双核 MESI 状态机 + 总线：BusRd/BusRdX(RFO)/写回/失效计数，false sharing 对比 |
| 6 | B3 内存一致性模型建模 | TSO store buffer vs SC：核心停顿、SB 满、fence 排空频率 |
| 7 | B4 预取/DRAM 建模 | bank/行缓冲（tRCD/tCAS/tRP）时序 + 步长预取器（度/距离、及时率、额外流量） |
| 8 | B5 NoC/NUMA 建模 | 4×4 mesh、XY 路由、逐 router 负载竞争、均匀 vs 热点、本地/远端延迟 |
| 9 | E2 CPI/Roofline/TopDown | 同一份事件计数产出三套归因：CPI 栈、Roofline（算术强度）、Top-Down 四桶 |
| 10 | E3 workload/采样 | 负载特征（MPKI/分支/访存比）+ 全跑 vs 朴素定步长采样 vs SimPoint 式按相位代表采样 |

## 设计原则

- **功能与性能分离**：这里全部是"性能/结构模型"，吃参数或合成 trace 记账周期，不模拟 ISA 功能结果（功能底座见上一批 [`../cpu-model-isa-iss`](../cpu-model-isa-iss/)）。
- **结构出数，不拍脑袋**：stall、缺失、一致性流量、队列竞争都从资源表/状态机/就绪时间里逐拍累加，而非直接按概率设定 IPC。
- **教学骨架、确定性**：固定随机种子，输出可复现；数字用于讲清趋势与量纲，不代表任何具体商用核。

## 一句话总结

core-mem-lab 是一个不依赖 SystemC 的自包含 C++17 实验台，用 10 个参数化周期记账模型对应流水线、分支预测、乱序、Cache、一致性、内存序、DRAM、NoC 等文章，逐拍累加结构数据而非假设 IPC。
