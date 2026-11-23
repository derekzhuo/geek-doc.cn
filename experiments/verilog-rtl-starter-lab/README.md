# Verilog RTL Starter Lab

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-verilog-rtl-starter-lab.html

五个可以在本机直接跑出波形的 Verilog 入门实验，不需要开发板、厂商 EDA 或 Docker，只要 [Icarus Verilog](https://steveicarus.github.io/iverilog/) 和 [GTKWave](https://gtkwave.sourceforge.net/) 两个免费工具。

## 你会学到什么

| 实验 | 主题 | 核心能力 |
|---|---|---|
| Lab 01 | 参数化时钟分频器 | 计数器、寄存器、参数化设计 |
| Lab 02 | 按键消抖 | 两级同步器、稳定计数窗、电平与脉冲输出 |
| Lab 03 | 「1101」序列检测器 | 有限状态机、Mealy 输出、重叠匹配 |
| Lab 04 | UART 发送器 | 并转串、波特率定时、起始/停止位帧格式 |
| Lab 05 | 参数化同步 FIFO | 读写指针、满空判定、边界读写保护 |

每个实验都包含可综合 RTL、带断言的 testbench、波形生成方式和一份讲清「波形怎么读」的说明。testbench 不是只打印信号，而是逐条检查预期行为，任何一条断言失败都会让仿真以非 0 退出码结束。

## 快速开始

安装工具（三平台详细步骤见 [docs/install-iverilog-gtkwave.md](docs/install-iverilog-gtkwave.md)）：

```bash
# macOS
brew install icarus-verilog gtkwave

# Ubuntu / Debian
sudo apt install iverilog gtkwave
```

Windows 用户安装 Icarus Verilog 官方安装包后，在 PowerShell 中使用 `.\run.ps1`，无需 make。

跑通全部五个实验：

```bash
make test          # macOS / Linux
./run.sh           # 等价入口
.\run.ps1          # Windows PowerShell
```

期望最后一行输出：

```text
RESULT: PASS 5/5
```

只想跑单个实验：

```bash
make lab04-uart-tx
```

第一次上手建议先读 [START-HERE.md](START-HERE.md)，用 10 分钟跑通 Lab 01 并看懂第一张波形。

## 目录结构

```text
verilog-rtl-starter-lab/
├── common/tb_tasks.vh        # 共享断言任务
├── lab01-clock-divider/      # 每个实验目录下：
├── lab02-debounce/           #   rtl/   可综合 RTL
├── lab03-seq-detector-fsm/   #   tb/    testbench
├── lab04-uart-tx/            #   waves/ 波形观察笔记
├── lab05-sync-fifo/          #   README.md
├── tests/run_all.sh          # 五实验汇总自检
├── docs/                     # 工具安装指南
├── Makefile / run.sh / run.ps1
├── VERSION / CHANGELOG.md
```

## 看波形

每次仿真会在对应实验的 `sim_build/` 下生成 VCD 文件：

```bash
gtkwave lab05-sync-fifo/sim_build/lab05.vcd
```

`sim_build/` 是本地产物，不进入版本库；执行 `make clean` 可全部清除。

## 学习建议

按 Lab 01 → 05 的顺序做，它们对应一条真实的能力递进线：先理解时钟和寄存器，再处理异步输入，然后写状态机和接口协议，最后做带缓冲的数据结构。每个 README 末尾都有「自己动手改一改」，建议改完参数后先预测波形，再跑仿真验证。

## 许可证

与仓库根目录 LICENSE 一致（MIT）。
