# flow-yosys-first-synth

**对应教程**：https://geek-doc.cn/eda/flow-yosys-first-synth.html

Yosys 第一次综合的最小可运行样例：对一个 4 位带使能与异步复位的计数器，按
`read_verilog → hierarchy -top → proc → opt → techmap → stat` 逐步走通，
每个阶段后插一条 `stat` 观察电路形态变化，最后 `write_verilog` 出门级网表。

## 文件

- `counter4.v`：最小可综合 RTL（4 位使能计数器 + 进位输出）
- `run.ys`：Yosys 脚本（分阶段 stat，techmap 后补一次 opt_clean）
- `Makefile`：一条命令跑完整条流程

## 复现

```bash
make run        # 需要本机有 docker 与 geek-eda:0.3-sta 镜像
```

本机原生安装了 Yosys 0.33 时也可以：

```bash
make run YOSYS="yosys"
```

跑完终端打印五个阶段的 `stat`，并生成门级网表 `netlist.v`（生成物，不入库）：

```bash
make clean
```
