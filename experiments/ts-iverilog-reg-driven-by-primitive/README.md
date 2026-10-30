# Icarus Verilog：reg 被原语或连续赋值驱动

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-reg-driven-by-primitive.html（上线后生效）

本目录提供 `reg` 作为连续赋值目标和门原语输出时的最小复现，以及分别改为 `wire` 和 `always @*` 过程赋值后的验证代码。

## 文件

- `bad.v`：连续赋值和 `buf` 原语都错误地驱动 `reg`。
- `fixed.v`：连续赋值目标改为 `wire`，原语逻辑改写成组合 `always` 块。
- `run.sh`：依次复现编译失败、验证修复版编译与仿真。

## 复现

需要 Icarus Verilog 13.0（本文实测版本）。在本目录执行：

```bash
bash run.sh
```

脚本预期 `bad.v` 编译失败、`fixed.v` 编译并运行成功，最后输出总体验证 `PASS`。
