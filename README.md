# 极客工场实验仓

> 这里收集极客工场文章里的实验。你可以先读教程，再在自己的机器上跑一遍；结果对不上时，也可以对照我们留下的日志、波形和报告，看看问题出在哪。

[![文档站](https://img.shields.io/badge/文档站-geek--doc.cn-2563eb)](https://geek-doc.cn)
[![实验索引](https://img.shields.io/badge/实验索引-持续更新-0f766e)](experiments/README.md)
[![License](https://img.shields.io/badge/License-MIT-475569)](LICENSE)
[![verify](https://github.com/derekzhuo/geek-doc.cn/actions/workflows/verify.yml/badge.svg)](https://github.com/derekzhuo/geek-doc.cn/actions/workflows/verify.yml)

![极客工场实验仓：读文章的时候，也可以动手试一试](assets/social-preview.svg)

## 想先试试？可以从这三类实验开始

| 学习方向 | 推荐实验 | 适合什么时候看 |
|---|---|---|
| **Linux 性能剖析** | [忙等待 vs 睡眠调度](experiments/busy-wait-vs-sleep/) · [缓存未命中](cache-miss/) · [perf 火焰图](perf-read-flamegraph/) | 想看程序为什么慢、CPU 为什么忙，并希望用数据验证自己的判断 |
| **开源 EDA** | [FIFO 入门工程](fifo-starter-kit/) · [Yosys 常见报错](experiments/eda-lab-yosys-common-errors/) · [OpenSTA 实验](experiments/opensta-create-clock-report/) | 想亲手跑一遍仿真、综合和时序分析，而不是只看命令截图 |
| **FPGA / Vivado / Quartus** | [Vivado RTL→Bitstream](experiments/vivado-rtl-to-bitstream-webpack/) · [XSim 设计单元排错](experiments/vivado-xsim-design-unit/) | 想跟着日志熟悉工具，遇到报错时知道下一步该查什么 |

暂时拿不定主意，也可以去 **[完整实验索引](experiments/README.md)** 按主题慢慢翻。

## 先跑两个小实验

```bash
git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn

# Linux / macOS：运行 FIFO 自校验回归
make -C fifo-starter-kit test

# Linux：编译并运行缓存访问模式实验
make -C cache-miss run
```

性能剖析实验通常依赖 Linux、`perf` 和 `/proc`；EDA 实验需要各自 README 标明的工具链。Vivado/Quartus 相关实验使用对应工具实际运行，需要的版本也会写在各实验的 README 里。

### 先给你看一组结果

以下是 `experiments/busy-wait-vs-sleep` 已归档的实测结果，运行环境和完整数据见 [results.txt](experiments/busy-wait-vs-sleep/results.txt)：

| 模型 | 单次延迟 | CPU 使用率 |
|---|---:|---:|
| 忙等待 | 1.245 μs | ~100% |
| 睡眠调度 | 8.92 μs | ~10% |

读结论时，你也可以继续往下看输入、输出和实验环境，不用只凭一句话判断它是否可信。

## 里面都有哪些实验

### 几条持续展开的系列

| 系列 | 内容 |
|---|---|
| [echo](echo/) | 高并发 TCP echo 服务器，渐进式代码与压测脚本 |
| [FIFO Starter Kit](fifo-starter-kit/) | 参数化同步 FIFO、自校验 testbench 和 VCD 波形 |
| [mini-agent](mini-agent/) | 从最小 Agent Loop 到工具调用的增量工程 |
| [vim-cpp](vim-cpp/) | 分阶段实现一个迷你 Vim |
| [CPU 微架构系列](cpu-model-core-mem-lab/) | 核存模型、ISA 模拟器、SystemC/TLM 等实验 |
| [perf 实验](cpu-demo/) | CPU、缓存、分支、调度、锁竞争和动态探针 |

### 文档内嵌实验

`experiments/` 当前收录 **339 个实验**，覆盖开源 EDA 入门、数字设计、OpenSTA、Vivado/XSim、排错案例、芯片参考和性能专题。每个目录都有独立 README。

**[查看全部 339 个实验 →](experiments/README.md)**

## 打开一个实验，你通常会看到

- 它要解决什么问题，以及需要哪些工具。
- 可以直接照着运行的命令，而不只是几段代码。
- 用来核对结果的日志、报告、数据、波形或截图。
- 对应的中文教程，忘了原理时可以回去接着读。
- 只保留源码和实验材料，编译产物与临时文件不会混进来。

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

**希望这些实验能帮你看懂原理，也少走一些配置环境的弯路。**
