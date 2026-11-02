# flow-verilator-into-ci

**对应教程**：https://geek-doc.cn/eda/flow-verilator-into-ci.html

Verilator 两段式 CI（lint gate -> sim gate）的最小可复现实例：一个 8 位可加载计数器 DUT、一个自校验 C++ harness、一份 GitHub Actions workflow，以及一个在本地把两道门禁原样跑一遍的 `run.sh`。

## 目录

```bash
.github/workflows/verilator-ci.yml   # CI 定义：lint 与 sim 两个 job
rtl/counter.v                        # 8 位计数器 DUT（异步复位/使能/并行加载）
sim/tb_counter.cpp                   # C++ 自校验 testbench，打印 TEST PASS/TEST FAIL
run.sh                               # 本地复演两道门禁（失败即非零退出）
Makefile                             # make run / make clean
```

## 复现

需要 Verilator 5.x 与 g++、make。

- 本机已装 Verilator：`make run`
- 用 Docker 镜像：`make run VERILATOR_IMG=<你的 verilator 镜像>`（教程实测镜像为 Verilator 5.020）

预期最后一行是 `ALL GATES PASS`，退出码 0。

想看 lint gate 变红：在 `rtl/counter.v` 的 `endmodule` 前加一行未使用信号，例如

```verilog
wire [7:0] next_q = q + 8'd1;
```

再跑 `make run`，lint 阶段报 `%Warning-UNUSEDSIGNAL` 并以退出码 1 中止，sim 阶段被跳过。删掉该行即恢复全绿。

## 说明

CI 的 GitHub Actions 采用 `ubuntu-24.04` 上 apt 安装 Verilator 的最小配置；本地实测在 Verilator 5.020 容器中完成，不同小版本的告警文本可能略有差异，但退出码语义一致。
