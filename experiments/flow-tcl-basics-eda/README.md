# flow-tcl-basics-eda

**对应教程**：https://geek-doc.cn/eda/flow-tcl-basics-eda.html

EDA 工具（OpenSTA / Yosys）里的 Tcl 最小可用集可复现实例：变量、列表、`foreach`、`proc`、命令查询五个语法件，每个都落在真实 EDA 命令组合场景。

## 文件

| 文件 | 作用 |
|---|---|
| `sta_flow.tcl` | OpenSTA Tcl 脚本：变量参数化、列表 + foreach 逐角点报告、proc 封装、集合遍历、`info commands`/`help` 查询 |
| `ys_flow.tcl` | Yosys Tcl 脚本：`yosys -import` 后用 foreach 批量读 RTL、proc 封装 stat、查询 synth 命令 |
| `tiny.lib` | 教学用最小 liberty（复用自 flow-opensta-first-sta，BUF_X1/NAND2_X1/DFF_P，产线替换为 PDK 库） |
| `top.v` | 两级 DFF 门级网表（复用自 flow-opensta-first-sta） |
| `rtl/gates.v`、`rtl/cnt.v` | 给 Yosys 批量读入演示用的两个小 RTL |
| `run.sh` | 一条命令在 docker 里跑通两个工具的全部脚本（带环境头） |
| `Makefile` | `make run` / `make sta` / `make yosys` |

## 复现

```bash
bash run.sh
# 或分步
make sta
make yosys
```

需要本地 Docker 镜像 `geek-eda:0.4-flow`（OpenSTA 2.0.17 / Yosys 0.33）。

## 要点

- OpenSTA 2.0.17 没有 `foreach_in_collection`，对象集合直接用普通 `foreach` 逐项取句柄，再 `get_property $obj full_name`。
- Yosys 的 Tcl 入口是 `yosys -p "tcl ys_flow.tcl"` 且脚本首行 `yosys -import`；`yosys -c x.tcl` 不导入综合命令。
- `yosys -import` 不覆盖 Tcl 内置命令：Yosys 的 proc pass 改名 `procs`，`cd/eval/exec/read/trace` 跳过导入。
