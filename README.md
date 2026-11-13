# 极客工场实验仓

面向**数字 IC、开源 EDA、FPGA、Linux 性能剖析与 AI 编程**的可复现实验集合。这里不只提供示例代码，也尽量保留运行方法、原始结果和对应中文教程，方便你从“看懂”走到“亲手验证”。

[![文档站](https://img.shields.io/badge/文档站-geek--doc.cn-2563eb)](https://geek-doc.cn)
[![实验索引](https://img.shields.io/badge/实验索引-持续更新-0f766e)](experiments/README.md)
[![License](https://img.shields.io/badge/License-MIT-475569)](LICENSE)
[![verify](https://github.com/derekzhuo/geek-doc.cn/actions/workflows/verify.yml/badge.svg)](https://github.com/derekzhuo/geek-doc.cn/actions/workflows/verify.yml)

![极客工场实验仓：读文章的时候，也可以动手试一试](assets/social-preview.svg)

[快速开始](#快速开始) · [实验方向](#实验方向) · [仓库结构](#仓库结构) · [贡献指南](CONTRIBUTING.md) · [问题反馈](https://github.com/derekzhuo/geek-doc.cn/issues)

> [!TIP]
> 第一次使用，建议先跑 [FIFO Starter Kit](fifo-starter-kit/START-HERE.md)。它只需要 Icarus Verilog，不需要 FPGA 开发板或商业仿真器。

## 实验方向

| 方向 | 推荐入口 | 可以动手验证什么 |
|---|---|---|
| **数字 IC / 开源 EDA** | [FIFO 入门工程](fifo-starter-kit/) · [Yosys 常见报错](experiments/eda-lab-yosys-common-errors/) · [OpenSTA 实验](experiments/opensta-create-clock-report/) | RTL 仿真、自校验测试、波形、综合和时序报告 |
| **FPGA / Vivado / Quartus** | [Vivado RTL→Bitstream](experiments/vivado-rtl-to-bitstream-webpack/) · [XSim 设计单元排错](experiments/vivado-xsim-design-unit/) | 工具流程、约束、仿真报错和日志定位 |
| **Linux 性能剖析** | [忙等待 vs 睡眠调度](experiments/busy-wait-vs-sleep/) · [缓存未命中](cache-miss/REPRO.md) · [perf 火焰图](perf-read-flamegraph/REPRO.md) | CPU 开销、缓存行为、采样分析和性能对照 |
| **AI 编程与底层原理** | [mini-agent](mini-agent/) · [CPU 微架构系列](cpu-model-core-mem-lab/) | Agent Loop、工具调用、ISA 模拟器和 SystemC/TLM |

不确定从哪里开始，可以在 **[完整实验索引](experiments/README.md)** 按主题查找。

## 快速开始

### 1. 获取代码

```bash
git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn
```

Git 和 Make 是多数独立实验的基础工具。具体依赖以各实验的 README 为准：EDA 实验需要相应仿真或综合工具，Linux 性能实验通常需要 C/C++ 编译器，部分实验还依赖 `perf` 和 `/proc`。

### 2. 跑通一个数字 IC 实验

Ubuntu / Debian 可先安装 Icarus Verilog：

```bash
sudo apt-get update
sudo apt-get install -y iverilog
```

运行 FIFO 自校验回归：

```bash
make -C fifo-starter-kit test
```

测试通过时，输出末尾包含：

```bash
RESULT: PASS
```

完整日志和 VCD 波形分别写入 `fifo-starter-kit/out/sim.log` 与 `fifo-starter-kit/out/sync_fifo.vcd`。Windows、macOS 和波形查看方法见 [START-HERE](fifo-starter-kit/START-HERE.md)。

### 3. 跑通一个 Linux 性能实验

```bash
make -C experiments/busy-wait-vs-sleep run
```

这个实验对比忙等待与睡眠调度的延迟和 CPU 开销。源码、复现命令和归档结果见 [实验说明](experiments/busy-wait-vs-sleep/README.md)。

## 如何阅读实验结果

以下是上述等待模型实验的一组已归档结果：

| 模型 | 单次延迟 | CPU 使用率 |
|---|---:|---:|
| 忙等待 | 1.245 μs | 约 100% |
| 睡眠调度 | 8.92 μs | 约 10% |

完整数据见 [results.txt](experiments/busy-wait-vs-sleep/results.txt)。这些数字用于解释对照关系，不是跨平台性能承诺；实际结果会受硬件、操作系统、编译器和负载影响。复现时请同时记录环境和输入参数，而不是只比较最终数值。

## 仓库结构

| 路径 | 内容 |
|---|---|
| [`experiments/`](experiments/README.md) | 与文档配套的主题实验，覆盖 EDA、数字设计、时序分析、FPGA 和性能专题 |
| [`fifo-starter-kit/`](fifo-starter-kit/) | 参数化同步 FIFO、自校验 testbench、回归脚本和 VCD 波形 |
| [`mini-agent/`](mini-agent/) | 从最小 Agent Loop 到工具调用的增量工程 |
| [`cpu-model-core-mem-lab/`](cpu-model-core-mem-lab/) | CPU 核存模型及后续 ISA、SystemC/TLM 系列入口 |
| [`echo/`](echo/) | 高并发 TCP echo 服务器的渐进式代码与压测脚本 |
| [`vim-cpp/`](vim-cpp/) | 分阶段实现一个迷你 Vim |
| 根目录其他实验 | 缓存、分支预测、锁竞争、调度延迟、信号和系统调用等独立示例 |

打开一个实验，通常可以找到：

- **目标与依赖**：验证什么问题，需要哪些工具和版本。
- **复现步骤**：可以直接执行的命令、输入和配置。
- **核对材料**：日志、报告、数据、波形或截图。
- **中文教程**：解释实验背后的原理和结果。
- **适用边界**：教学实验与实际项目、工业签核之间的区别。

## 常用命令

```bash
make -C <demo>          # 编译
make -C <demo> run      # 编译并运行
make -C <demo> test     # 运行测试（实验提供该目标时）
make -C <demo> clean    # 清理生成物
```

维护实验索引和文档链接需要 Node.js 20+：

```bash
node scripts/gen-experiment-index.mjs
node scripts/check-experiment-docs.mjs
```

## 文档、提问与贡献

- 完整原理和系列教程：[极客工场文档站](https://geek-doc.cn)
- 按主题查找实验：[实验索引](experiments/README.md)
- 新增或改进实验：[贡献指南](CONTRIBUTING.md)
- 安全问题：[安全说明](SECURITY.md)

运行遇到问题，欢迎提交 [Issue](https://github.com/derekzhuo/geek-doc.cn/issues)。请附上操作系统、工具版本、完整命令和原始错误输出，这些信息通常比一张报错截图更有助于定位问题。

## 许可证

本仓库代码与实验材料采用 [MIT License](LICENSE)，除非具体目录另有说明。
