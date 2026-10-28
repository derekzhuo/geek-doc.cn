# geek-doc.cn — 「极客工场」配套可运行实验代码集

> 与中文技术知识库「极客工场」[geek-doc.cn](https://geek-doc.cn) 配套的**可运行实验代码**：覆盖 Linux 性能剖析、开源 EDA 工具链、Vivado/FPGA 实战、CPU 微架构建模等。
> 每个 demo 独立可编译、可运行，`make run` 即出结果。

[![Site](https://img.shields.io/badge/站点-geek-doc.cn-blue?style=flat-square&logo=readthedocs&logoColor=white)](https://geek-doc.cn)
[![Demos](https://img.shields.io/badge/实验-110%2B%20个可跑-orange?style=flat-square)](https://geek-doc.cn/demos/)

## 快速开始

```bash
git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git
cd geek-doc.cn
make -C cpu-demo run        # 跑第一个 demo：CPU 使用率三场景
```

> 运行要求：性能剖析类 demo 依赖 Linux（`/proc`、`perf` 等），macOS 可编译多数 demo 但部分输出不同；EDA 类实验需要对应工具链（iverilog / verilator / yosys / cocotb / Vivado 等，各实验 README 有说明）。
>
> 📖 配套理论讲解、perf 命令逐行解读与原始输出分析，全在站点的 **「perf 实验」栏目**：[geek-doc.cn/demos/](https://geek-doc.cn/demos/)。

## 目录总览

每个 demo 的**完整理论讲解**都对应站点里的专属文档页，地址格式 `https://geek-doc.cn/demos/<demo>/`：

| # | demo | 主题 | 运行 |
|:-:|------|------|------|
| D1/D2 | [cpu-demo](cpu-demo/) | CPU 使用率三场景 + perf stat/record 基础 | `make -C cpu-demo run` |
| D3 | [tlb-thrashing](tlb-thrashing/) | TLB 页表缓存抖动实验 | `make -C tlb-thrashing run` |
| D4 | [cache-miss](cache-miss/) | 缓存未命中模式（顺序/随机/跨步） | `make -C cache-miss run` |
| D5 | [branch-predict](branch-predict/) | 分支预测（有序/随机/无分支） | `make -C branch-predict run` |
| D6 | [stall-analysis](stall-analysis/) | 流水线停顿（前端 vs 后端） | `make -C stall-analysis run` |
| D7 | [syscall-trace](syscall-trace/) | 系统调用追踪实验 | `make -C syscall-trace run` |
| D8 | [lock-contention](lock-contention/) | 锁争用诊断实验 | `make -C lock-contention run` |
| D9 | [false-sharing](false-sharing/) | 伪共享检测实验（perf c2c） | `make -C false-sharing run` |
| D10 | [sched-latency](sched-latency/) | 调度延迟诊断实验 | `make -C sched-latency run` |
| D11 | [perf-probe](perf-probe/) | 动态探针插桩实验（perf probe/USDT） | `make -C perf-probe run` |
| D12 | [perf-bench-diff](perf-bench-diff/) | 微基准 + 优化对比实验 | `make -C perf-bench-diff run` |
| D13 | [indirect-branch](indirect-branch/) | 间接分支预测（虚函数/函数指针/switch） | `make -C indirect-branch run` |
| D14 | [mt-io-demo](mt-io-demo/) | 多线程 + IO 分析方法演练 | `make -C mt-io-demo run` |
| - | [compiler-reordering](compiler-reordering/) | 编译器重排与 data-race UB | `make -C compiler-reordering run` |
| - | [crash-signals](crash-signals/) | 崩溃信号复现（10 个程序） | `make -C crash-signals run` |
| E1 | [echo](echo/) | 高并发 TCP echo 服务器实战（day-01 ~ day-06 渐进式代码与压测脚本） | `make -C echo/day-01`（再分别 `run-server` / `run-client`） |

> 💡 记不住地址？直接收藏 [geek-doc.cn/demos/](https://geek-doc.cn/demos/)（站点左侧目录「perf 实验索引」）——每个 demo 都有对应页面，含复现命令、代码讲解与实测数据。

## 专题实战目录（仓库根下）

| 目录 | 主题 | 说明 |
|------|------|------|
| [echo](echo/) | 高并发 TCP echo 服务器实战 | day-01 ~ day-06 渐进式代码与压测脚本 |
| [cpu-model-core-mem-lab](cpu-model-core-mem-lab/) | CPU 核-存模型实验 | 配套「CPU 微架构」系列 |
| [cpu-model-isa-iss](cpu-model-isa-iss/) | ISA 指令集模拟器（ISS） | 配套「CPU 微架构」系列 |
| [cpu-model-sim-platform-lab](cpu-model-sim-platform-lab/) | 仿真平台实验 | 配套「CPU 微架构」系列 |
| [cpu-model-systemc-tlm-lab](cpu-model-systemc-tlm-lab/) | SystemC/TLM 建模实验 | 配套「CPU 微架构」系列 |
| [demos/fpga-beginner](demos/fpga-beginner/) | FPGA 入门实验 | 组合逻辑、LED 计数器、仿真、XDC/GPIO |
| [perf-read-flamegraph](perf-read-flamegraph/) | perf + 火焰图实战 | 热点定位完整演练 |
| [signal-vs-eventfd](signal-vs-eventfd/) | 信号 vs eventfd 对比 | Linux 事件通知机制 |
| [signals-demos](signals-demos/) | 信号机制系列 demo | alarm / signalfd / sigwait 等 |
| [c-beginner-practice](c-beginner-practice/) | C 语言入门练习 | 配套「C 语言」系列 |
| [cpp-beginner-practice](cpp-beginner-practice/) | C++ 入门练习 | 配套「C++」系列 |
| [design-patterns](design-patterns/) | 设计模式 25 个示例 | 每模式一个独立 `.cpp`，对照类图阅读 |
| [vim-cpp](vim-cpp/) | 动手写一个 vim（mini-vim） | vc-01 ~ vc-06 六个渐进阶段，配套实现系列文 |

## 文档内嵌实验归档（experiments/，84 个）

站点理论文档中出现的**内嵌实验**（代码写在讲解页里、不在顶层 demo 下），代码与实测日志统一归档于此，每个实验自带 README 与 `output/` 实测输出，随新文档持续补充。按主题分组：

| 分组 | 数量 | 代表实验 |
|------|-----:|----------|
| 开源 EDA 入门（`eda-lab-*`） | 12 | [iverilog 第一次仿真](experiments/eda-lab-iverilog-first-sim/)、[verilator lint](experiments/eda-lab-verilator-lint/)、[yosys 综合分步](experiments/eda-lab-yosys-synth-steps/) |
| 数字设计技巧实验（`exp-*`） | 18 | [valid/ready 握手波形](experiments/exp-valid-ready-handshake-wave/)、[异步 FIFO cocotb 验证](experiments/exp-async-fifo-cocotb-verify/)、[CDC 毛刺](experiments/exp-multibit-cdc-glitch/) |
| OpenSTA 时序分析 | 5 | [create_clock 与报告解读](experiments/opensta-create-clock-report/)、[setup 检查原理](experiments/sta-setup-check-principle-opensta/)、[多周期路径](experiments/opensta-multicycle-path-example/) |
| 验证方法学（SVA / cocotb） | 3 | [SVA 断言入门（sby）](experiments/sva-assertion-basics-sby/)、[SV 随机约束 vs cocotb](experiments/sv-constraint-random-vs-cocotb/) |
| Vivado / XSim 实战 | 11 | [RTL 到 bitstream（WebPACK）](experiments/vivado-rtl-to-bitstream-webpack/)、[XDC 时序约束对比](experiments/vivado-xdc-timing-compare/)、[利用率报告解读](experiments/vivado-utilization-report-read/) |
| 排错案例库（`ts-*` / errlog） | 15 | [iverilog 常见报错](experiments/eda-lab-iverilog-common-errors/)、[verilator MULTIDRIVEN](experiments/ts-verilator-multidriven-MULTIDRIVEN/)、[yosys 打不开输入文件](experiments/ts-yosys-cant-open-input-file/) |
| 芯片参考资料（`chip-ref-*`） | 10 | [STM32F103](experiments/chip-ref-stm32f103c8t6/)、[ESP32-WROOM-32](experiments/chip-ref-esp32-wroom-32/)、[NE555](experiments/chip-ref-ne555/) |
| 其它 EDA 流程 | 7 | [AXI4 时序波形走读](experiments/axi4-timing-waveform-walkthrough/)、[LEC 等价检查](experiments/lec-yosys-equiv-opt/)、[Quartus 第一个工程](experiments/quartus-lite-first-project/) |
| 性能内嵌实验 | 3 | [numa-access](experiments/numa-access/)（跨 NUMA ~3x）、[busy-wait-vs-sleep](experiments/busy-wait-vs-sleep/)、[spsc-mpsc-queue](experiments/spsc-mpsc-queue/)（SPSC 无锁 vs 有锁 ~20x） |

## 常用命令

```bash
make -C <demo>            # 编译（默认 -O0 -g，保留 perf 符号）
make -C <demo> run        # 编译并运行
make -C <demo> release    # 以 -O2 编译对比（观察优化器效果）
make -C <demo> clean      # 清理
```

## 配套理论文档

这里只提供**可运行代码**；每个实验背后的原理、`perf` 工具用法、原始输出与逐行分析，请到配套文档站阅读：

- **站点首页**：[geek-doc.cn](https://geek-doc.cn)
- **perf 实验栏目**：[geek-doc.cn/demos/](https://geek-doc.cn/demos/)
- 站内搜索「性能剖析」「perf」即可直达对应理论章节

> 为什么"跑"和"读"分开？因为**代码就该能跑，原理就该讲透**——在站点读完理论，回这里 `make run` 亲手验证，效果最好。

## 许可

[MIT](LICENSE) — 自由使用、修改、再分发，仅需保留版权声明。

---

**站点**：[geek-doc.cn](https://geek-doc.cn) · 喜欢这个仓库的话，欢迎在 GitHub 点个 ⭐
