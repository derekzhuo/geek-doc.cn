# Verilator --binary 与 --cc 两种仿真模式对照实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-binary-mode.html

同一个 8 位带使能计数器 `counter.v`，分别用 Verilator 5.x 的两种模式跑通：

- 模式 A（`--binary`）：`counter.v` + 行为级 `tb_counter.v` 一条命令直接编成可执行文件，
  main 由 Verilator 自动生成，产物在 `obj_dir_bin/Vtb_counter`。
- 模式 B（`--cc`）：只把 RTL 翻译成 C++（`obj_dir_cc/`），入口 `tb_main.cpp` 手写，
  再自己调 `make -f Vcounter.mk` 完成 g++ 编译，产物在 `obj_dir_cc/Vcounter`。

## 复现

需要 Docker 与 `geek-eda:0.3-sta` 镜像（Verilator 5.020）：

```bash
make run      # 容器内顺序执行两种模式
make clean    # 删除 obj_dir_bin / obj_dir_cc
```

两种模式末尾都应打印 `TEST PASS`。

## 文件说明

| 文件 | 作用 |
|---|---|
| `counter.v` | 8 位带使能计数器（异步复位，计到 255 时 carry 拉高） |
| `tb_counter.v` | 行为级 Verilog testbench，仅模式 A 使用（带 `#` 延迟，需 `--timing`） |
| `tb_main.cpp` | 手写 C++ harness，仅模式 B 使用 |
| `run.sh` | 容器内执行的完整对照脚本 |
