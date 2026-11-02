# Verilator --cc 编译仿真最小实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-cc-simulation.html

用一个 4 位计数器（每 16 拍产生一个分频脉冲 `tick`）走通 Verilator 最经典的 `--cc` 链路：`verilator --cc --exe --trace` 生成 C++ 与 Makefile，手写 C++ testbench harness（`Vtop.h`、`eval()`、trace 开关），`make -f Vtop.mk` 编译，运行 `./obj_dir/Vtop` 自校验。

## 文件

| 文件 | 说明 |
|------|------|
| `top.v` | DUT：4 位计数器 + 分频脉冲 |
| `tb_top.cpp` | 手写 C++ harness，含复位/时钟/自校验与 `--trace` 波形开关 |
| `run-native.sh` | 容器或本机执行的三步命令 |
| `run.sh` | 一键起 `geek-eda:0.3-sta` 容器复现 |
| `Makefile` | `make run` / `make clean` |

## 复现

需要 Docker 与镜像 `geek-eda:0.3-sta`（Verilator 5.020、g++、make）：

```bash
make run        # 等价于 ./run.sh
make clean      # 删除 obj_dir/ 与 wave.vcd
```

本机已装 Verilator 5.x 时可直接 `make NATIVE=1 run`。

预期输出末尾为：

```text
ticks=2 final q=8
RESULT: PASS
```

加 `--trace` 的第二次运行会在当前目录生成 `wave.vcd`，可用 gtkwave 打开。
