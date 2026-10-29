# Verilator CONTASSREG 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-contassreg.html（上线后生效）

这组实验复现 Verilog `reg` 被 `assign` 连续赋值驱动的 CONTASSREG 警告，并验证三种修复：SystemVerilog `logic`、Verilog `wire`、保留 `reg` 改用组合过程赋值。

## 运行环境

- Docker 镜像：`geek-eda:0.2`
- Verilator：5.020

在本目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本要求 `broken.v` 非零退出，`fixed_logic.sv`、`fixed_wire.v`、`fixed_proc.v` 均为零退出，最后输出 PASS。也可在已安装同版本 Verilator 的 Linux 环境直接执行 `bash run.sh`。
