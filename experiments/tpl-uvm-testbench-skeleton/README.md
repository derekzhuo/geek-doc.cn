# UVM 验证平台骨架模板：可运行简化版与完整 UVM 五件套

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-uvm-testbench-skeleton.html

配套「UVM 验证平台骨架模板」一文的实验代码，分两部分：

- `sim/`：**不依赖 UVM 库的最小 SystemVerilog 骨架**。用普通 class、mailbox、virtual interface 复刻 sequencer/driver/monitor/scoreboard/test 五件套的职责与 phase 顺序，可用开源 Verilator 直接编译运行。
- `uvm/`：**完整 UVM 五件套模板**（`uvm_component_utils` 工厂注册、config_db、analysis port、objection、covergroup subscriber），需要带 UVM 库的商用或开源仿真器（VCS / Questa / Xcelium / Verilator+UVM 等），文件清单见 `uvm/filelist.f`。

## 目录结构

```text
.
├── run.sh            # 编译并运行简化版（Verilator）
├── sim/              # 可运行：去 UVM 依赖的简化 SV 骨架 + DUT
│   ├── dut_if.sv
│   ├── dut.sv        # data+1 流水线；+inject_bug 时算成 data+2
│   ├── tb_classes.sv # sequencer/driver/monitor/scoreboard/base_test
│   └── top.sv
└── uvm/              # 模板：真实 UVM 五件套（需 UVM 仿真器）
    ├── filelist.f
    ├── my_item.sv / my_sequencer.sv / my_driver.sv
    ├── my_monitor.sv / my_scoreboard.sv / my_coverage.sv
    ├── my_agent.sv / my_env.sv / my_test.sv
    └── top_tb.sv
```

## 复现方式

需要安装 Verilator 5.020+，或使用 geek-eda:0.4-flow 镜像：

```bash
# 故障注入：scoreboard 报 8/8 MISMATCH
INJECT_BUG=1 ./run.sh

# 修复后（去掉 +inject_bug）：8 items matched，TEST PASS
./run.sh
```

容器内执行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow \
  bash -c 'INJECT_BUG=1 ./run.sh; ./run.sh'
```

`INJECT_BUG=1` 给仿真器传 `+inject_bug`，DUT 把输出算成 data+2，scoreboard 逐笔打印 `MISMATCH`；不带该参数时 DUT 输出 data+1，全部匹配。

## 说明

简化版刻意省略了 UVM 的工厂重载、phase 自动调度与 TLM 层次，只保留「事务如何从 sequence 流到引脚、再被 monitor 抓回 scoreboard 比对」这条主干，便于在没有 UVM 仿真器时理解平台骨架；工程代码请以 `uvm/` 目录的完整模板为起点。
