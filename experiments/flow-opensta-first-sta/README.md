# flow-opensta-first-sta

**对应教程**：https://geek-doc.cn/eda/flow-opensta-first-sta.html

第一次跑 OpenSTA 静态时序分析的最小可复现实例：自己写的教学用最小 liberty 库（`BUF_X1` / `NAND2_X1` / `DFF_P` 三个单元，带一维负载查表延迟与 setup/hold 约束）+ 手写门级网表（两级 DFF 之间穿过 NAND 与 BUF）+ 一条 `create_clock` SDC。

## 文件

| 文件 | 作用 |
|---|---|
| `tiny.lib` | 教学用最小 liberty，单位 1ns/1pf，组合单元延迟按输出负载一维查表 |
| `top.v` | 门级网表：u_a/Q → NAND2_X1 → BUF_X1 → u_b/D（真实流程中由综合器 write_verilog 产出） |
| `constraints.sdc` | 最小 SDC，在 clk 端口建 1.0ns 周期时钟 |
| `run_sta.tcl` | STA 命令序列：read_liberty → read_verilog → link_design → read_sdc → report_checks |
| `run.sh` | 一条命令在 docker 里跑完全部报告（带环境头） |
| `Makefile` | `make run` 等价封装 |

## 复现

```bash
# 用本机安装的 OpenSTA 2.0.17
sta -no_init -exit run_sta.tcl

# 或用 docker 镜像 geek-eda:0.3-sta
make run
# 等价于：
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta sta -no_init -exit run_sta.tcl
```

预期结果：setup（path_delay max）slack 0.486 MET，hold（path_delay min）slack 0.373 MET。

**注意**：`tiny.lib` 是教学用最小库，所有延迟数值仅用于演示 STA 流程与报告读法，不能外推为任何工艺的签核结论；产线请替换为 sky130 等真实 PDK 库。
