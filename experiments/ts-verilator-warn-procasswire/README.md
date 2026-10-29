# Verilator PROCASSWIRE 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-procasswire.html（上线后生效）

这组实验复现 Verilog `wire` 在 `always @*` 中被过程赋值导致的 PROCASSWIRE，并验证三种修复：保留 `wire` 改用连续赋值、改用 Verilog `reg` 保留过程赋值、改用 SystemVerilog `logic` 与 `always_comb`。

## 运行环境

- Docker 镜像：`geek-eda:0.2`
- Verilator：5.020

在本目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本要求 `broken.v` 非零退出，`fixed_assign.v`、`fixed_reg.v`、`fixed_logic.sv` 均为零退出，最后输出 PASS。`run1.log` 是同环境运行保存的原始输出。也可在已安装同版本 Verilator 的 Linux 环境直接执行 `bash run.sh` 或 `make run`。
