# 极客工场实验仓

> Linux 性能剖析、开源 EDA、FPGA 与 CPU 微架构的可运行实验。每个实验都配套中文教程、复现命令和真实实验材料。

[![文档站](https://img.shields.io/badge/文档站-geek--doc.cn-2563eb)](https://geek-doc.cn)
[![实验索引](https://img.shields.io/badge/实验索引-持续更新-0f766e)](experiments/README.md)
[![License](https://img.shields.io/badge/License-MIT-475569)](LICENSE)

![极客工场实验仓：代码能跑，原理讲透，数据可复现](assets/social-preview.svg)

## 从这里开始

| 学习方向 | 推荐实验 | 你会得到什么 |
|---|---|---|
| **Linux 性能剖析** | [忙等待 vs 睡眠调度](experiments/busy-wait-vs-sleep/) · [缓存未命中](cache-miss/) · [perf 火焰图](perf-read-flamegraph/) | 可重复的性能数据、perf 分析和代码级解释 |
| **开源 EDA** | [FIFO 入门工程](fifo-starter-kit/) · [Yosys 常见报错](experiments/eda-lab-yosys-common-errors/) · [OpenSTA 实验](experiments/opensta-create-clock-report/) | RTL、testbench、综合/时序报告和完整回归 |
| **FPGA / Vivado / Quartus** | [Vivado RTL→Bitstream](experiments/vivado-rtl-to-bitstream-webpack/) · [XSim 设计单元排错](experiments/vivado-xsim-design-unit/) | 真实工具输出、约束/仿真验证和排错路径 |

不知道选哪一个？进入 **[完整实验索引](experiments/README.md)**，按主题、教程和实验材料筛选。

## 快速运行

```bash
git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn

# Linux / macOS：运行 FIFO 自校验回归
make -C fifo-starter-kit test

# Linux：编译并运行缓存访问模式实验
make -C cache-miss run
```

性能剖析实验通常依赖 Linux、`perf` 和 `/proc`；EDA 实验需要各自 README 标明的工具链。商业工具实验不会被伪装成开源替代品，Vivado/Quartus 的结果来自对应工具的真实运行。

### 真实结果长什么样

以下是 `experiments/busy-wait-vs-sleep` 已归档的实测结果，运行环境和完整数据见 [results.txt](experiments/busy-wait-vs-sleep/results.txt)：

| 模型 | 单次延迟 | CPU 使用率 |
|---|---:|---:|
| 忙等待 | 1.245 μs | ~100% |
| 睡眠调度 | 8.92 μs | ~10% |

仓库强调的不只是“有代码”，还包括**输入、输出、对照数据、实验环境和教程回链**。

## 仓库内容

### 旗舰系列

| 系列 | 内容 |
|---|---|
| [echo](echo/) | 高并发 TCP echo 服务器，渐进式代码与压测脚本 |
| [FIFO Starter Kit](fifo-starter-kit/) | 参数化同步 FIFO、自校验 testbench 和 VCD 波形 |
| [mini-agent](mini-agent/) | 从最小 Agent Loop 到工具调用的增量工程 |
| [vim-cpp](vim-cpp/) | 分阶段实现一个迷你 Vim |
| [CPU 微架构系列](cpu-model-core-mem-lab/) | 核存模型、ISA 模拟器、SystemC/TLM 等实验 |
| [perf 实验](cpu-demo/) | CPU、缓存、分支、调度、锁竞争和动态探针 |

### 文档内嵌实验

`experiments/` 当前收录 **276 个实验**，覆盖开源 EDA 入门、数字设计、OpenSTA、Vivado/XSim、排错案例、芯片参考和性能专题。每个目录都有独立 README。

**[查看全部 276 个实验 →](experiments/README.md)**

## 每个实验的交付约定

- 独立目录与 README，说明学习目标和工具链。
- 给出可执行的复现命令，而不是只贴代码片段。
- 保留适用的日志、报告、数据、波形或截图。
- 链接对应的中文教程，便于先读原理再动手验证。
- 编译产物、临时文件和敏感信息不进入仓库。

新增实验请阅读 [贡献指南](CONTRIBUTING.md)。运行遇到问题，可以通过 [Issue](https://github.com/derekzhuo/geek-doc.cn/issues) 提交环境、完整命令和原始错误输出。

## 常用命令

```bash
make -C <demo>          # 编译
make -C <demo> run      # 编译并运行
make -C <demo> clean    # 清理生成物

# 更新并检查实验索引（需要 Node.js 20+）
node scripts/gen-experiment-index.mjs
node scripts/check-experiment-docs.mjs
```

## 文档与许可

- [极客工场文档站](https://geek-doc.cn)
- [完整实验索引](experiments/README.md)
- [贡献指南](CONTRIBUTING.md) · [安全说明](SECURITY.md)
- [MIT License](LICENSE)

**代码能跑，原理讲透，数据可复现。**
