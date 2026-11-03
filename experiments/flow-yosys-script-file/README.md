# flow-yosys-script-file

**对应教程**：https://geek-doc.cn/eda/flow-yosys-script-file.html

Yosys 脚本文件（.ys）工程化组织的最小可运行样例：一个两层参数化设计
（`acc` 顶层例化 `adder` 子模块），脚本按「读入 → 定顶 → 综合 → 出图 →
落盘」分节、每节配注释，用 `yosys -s run.ys` 执行；并用
`show -format dot -prefix ...` 在综合前后各导出一张 Graphviz 结构图，
容器内 graphviz 的 `dot` 渲染成 PNG。

## 文件

- `adder.v`：参数位宽的行波加法器子模块
- `acc.v`：4 位累加器顶层（例化 adder，带使能与异步复位）
- `run.ys`：分节组织的 Yosys 脚本（含两处 show 出图）
- `Makefile`：一条命令跑完综合与出图

## 复现

```bash
make run        # 需要本机有 docker 与 geek-eda:0.4-flow 镜像
```

跑完生成（生成物，`make clean` 删除，不入库）：

- `netlist.v`：通用门级网表（write_verilog 产物）
- `acc_rtl.dot` / `acc_rtl.png`：综合前 RTL 级结构图
- `acc_gate.dot` / `acc_gate.png`：综合后通用门级结构图（每个模块一页）

本机原生安装了 Yosys 0.33 与 graphviz 时也可以：

```bash
make run RUN=""
```
