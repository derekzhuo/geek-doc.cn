# Yosys 网表接 OpenSTA 的衔接流程（最小可复现实验）

**对应教程**：https://geek-doc.cn/eda/flow-opensta-from-yosys-netlist.html

把一份两级流水 RTL 用 Yosys 0.33 综合、映射到自写教学用最小 liberty（`DFF_P` / `NAND2_X1` / `INV_X1` / `BUF_X1`，标量延时），`write_verilog` 出门级网表，再由 OpenSTA 2.0.17 读同一套库与网表出 setup/hold 报告。

> `teaching.lib` 是教学用最小库，数值自洽但不对应任何真实工艺；产线请替换为 sky130 等 PDK 库，结论不外推。

## 文件

| 文件 | 作用 |
|---|---|
| `rtl.v` | RTL 源（两级 DFF + 两级 NAND 门控子模块，故意保留层次） |
| `teaching.lib` | 教学用最小 liberty，Yosys 与 OpenSTA 共用同一份 |
| `constraints.sdc` | 一条 `create_clock`，周期 1.0ns |
| `synth.ys` | Yosys 脚本：read/synth -flatten/dfflibmap/abc/stat/write_verilog |
| `sta_setup.tcl` / `sta_hold.tcl` | OpenSTA setup(max) / hold(min) 脚本，各自独立进程 |
| `run.sh` | 全链一键跑（含两个反例：顶层名写错、漏 dfflibmap） |

## 复现

需要 docker 镜像 `geek-eda:0.3-sta`（Yosys 0.33 + OpenSTA 2.0.17）：

```bash
make run        # 全链：综合 + 网表 + setup/hold + 两个反例
make synth      # 只综合，产物 netlist.v
make sta-setup  # 只跑 setup（期望 slack 0.480 MET）
make sta-hold   # 只跑 hold（期望 slack 0.400 MET）
```

关键路径：Tco 0.200 + NAND 0.100 + NAND 0.120 = 到达 0.420；1.0ns 周期减 setup 0.100，setup slack 0.480 MET；hold 要求 0.020，hold slack 0.400 MET。
