---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/cpu-model-sim-platform-lab/`，配套页面 https://geek-doc.cn/demos/cpu-model-sim-platform-lab/


# cpu-model-sim-platform-lab

CPU 微架构建模系列第五批（**E4/E5、F1–F5、G1–G3**，共 10 篇）共用的**自包含 C++17 实验台**。
不依赖 gem5/QEMU/Spike/SystemC 或任何外部库，用一个文件内可读的小模型把这些**仿真器与平台工程机制**真实跑出数据：架构级功耗记账与 DVFS、设计空间探索的敏感性/Pareto、gem5 SE/FS 取舍与提速杠杆、QEMU/TCG 的功能速度、ISS 黄金模型 lockstep 对拍、协同仿真 transactor、配置校验/黄金向量、多 seed 回归的置信区间与退化报警、虚拟原型的速度-保真度菜单。

> 这里的 gem5/QEMU/Spike 数字是**量级教学模型**（典型 MIPS/加速比的数量级），用于讲清机制与权衡，不是某一具体工具版本的实测；生产分析请以所用工具版本的实测与官方手册为准。真正跑这些仿真器的命令与配置在对应文章里给出。

## 构建与运行

```bash
make            # g++ -O2 -std=c++17 -Wall -Wextra
./lab all       # 全部 10 个实验
./lab 1         # 只跑第 n 个（1..10）
```

实测环境：CentOS 7 + devtoolset-10（GCC 10.2.1），`-Wall -Wextra` 零警告。

## 实验目录

| 编号 | 文章 | 模型内容 |
|---|---|---|
| 1 | E4 功耗/面积 | 按访问次数×能量/访问记账（ALU/L1/L2/DRAM/分支/时钟），总能量→平均功耗；DVFS 扫 V/f 展示 V² 能量下降与时间代价 |
| 2 | E5 DSE/敏感性 | 单变量 OAT 敏感性（宽度/ROB/L2）+ 36 点网格 DoE，提取非支配 Pareto 前沿（11 点） |
| 3 | F1 gem5 SE/FS | SE ~4.2 M/s 无 OS vs FS ~0.31 M/s 真 OS；10k 首页在 SE/FS 的缺页差异 |
| 4 | F2 gem5 二开 | 100M 指令：全 timing 500s → atomic ffwd 7.4× → KVM ffwd 9.9× → KVM+1% 采样 91×；自定义指令加 3 拍记账 |
| 5 | F3 QEMU/TCG | QEMU 900 MIPS（功能）vs plugin 820（~9% 开销）vs gem5 atomic 5 vs timing O3 0.2 |
| 6 | F4 ISS/Spike | RV32I ADDI 黄金模型 vs 一个漏符号扩展的 DUT：golden x1=8、DUT=8200，在第 2 条动态指令首次分歧 |
| 7 | F5 协同 transactor | 一笔 burst → 逐拍 valid/ready 引脚事件（4/16/64 beat）；同步粒度 G 与域间漂移 |
| 8 | G1 C++/Python 工程 | 参数校验（宽度/ROB≥宽度/L2 二幂/频率）四组非法用例全捕获 + 黄金向量 |
| 9 | G2 回归/统计 | 20 seed 多跑：baseline/good/regressed 的均值±95% CI，-7.12% 退化触发报警、-0.37% 判为噪声 |
| 10 | G3 虚拟原型 | LT+DMI 12 MIPS → OoO LT 4 → AT 0.3 → CA 0.02；10M 指令启动的宿主机耗时对照 |

## 设计原则

- **机制出数**：Pareto 支配判定、置信区间、lockstep 首分歧、量子漂移都来自真实控制流/统计，而非打印假数据。
- **量级可信、非工具实测**：仿真器速度是数量级教学值，用于选型直觉；文中另给真实工具的获取/运行方式。
- **确定性**：统计实验固定随机种子（mt19937 seed=12345），输出可复现。
- 上游 SystemC/TLM 内核与事务机制见 [`../cpu-model-systemc-tlm-lab`](../cpu-model-systemc-tlm-lab/)；CPU 结构/内存记账模型见 [`../cpu-model-core-mem-lab`](../cpu-model-core-mem-lab/)；ISA 功能底座见 [`../cpu-model-isa-iss`](../cpu-model-isa-iss/)。

## 一句话总结

sim-platform-lab 用自包含 C++17 模型把功耗记账、DSE、gem5/QEMU 提速、ISS 对拍、协同仿真、回归置信区间、虚拟原型等平台机制真实跑出数据；其中仿真器速度是数量级教学值，非工具实测。
