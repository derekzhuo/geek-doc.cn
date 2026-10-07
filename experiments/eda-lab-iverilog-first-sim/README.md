# eda-lab-iverilog-first-sim

Icarus Verilog（iverilog）仿真入门实验：4 位计数器 + testbench，
编译 → 运行 → `$dumpvars` 导出 VCD 波形。

## 文件

- `counter.v` —— 被测设计（DUT），同步复位、使能计数的 4 位计数器
- `counter_tb.v` —— 测试平台，产生 10ns 时钟与激励，`$dumpvars` 导出 `out/counter.vcd`
- `Makefile` —— `make run` 一键编译运行，日志存 `out/sim.log`
- `out/` —— 运行产物（`counter_sim.vvp`、`counter.vcd`、`sim.log`）

## 运行（Docker，geek-eda:0.1）

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-iverilog-first-sim geek-eda:0.1 make run
```

本机已装 iverilog 时也可直接 `make run`。

配套文档：极客教程 geek-doc.cn「iverilog 仿真入门」篇（eda-lab/sim/）。
