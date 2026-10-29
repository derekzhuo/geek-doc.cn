# Icarus Verilog include 搜索路径最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-include-file-not-found.html（上线后生效）

本实验用两个头文件区分当前工作目录与 `-I` 搜索路径：`src/local.svh` 位于源码目录，`include/config.svh` 位于独立头文件目录。`src/top.sv` 同时包含二者，并检查宏展开后的值。

## 复现

需要 Icarus Verilog。本文记录使用 Icarus Verilog 13.0 (stable) (v13_0)。

```bash
bash run.sh
```

脚本合并标准输出和标准错误，逐项核对预期退出码，最后打印总 PASS。故障用例的预期退出码为 1，修复编译及仿真的预期退出码为 0。

- 根目录不带 `-I`：`local.svh` 找不到。
- 根目录只加 `-Isrc`：错误推进到 `config.svh`。
- 根目录加 `-Isrc -Iinclude`：编译和仿真通过。
- 从 `src/` 启动不带 `-I`：`local.svh` 已能找到，但 `config.svh` 找不到。
- 从 `src/` 启动加 `-I../include`：编译和仿真通过。

`run1.log` 是上述命令的完整原始记录，包含命令、日期、工具链、诊断和退出码。`build/` 为本地编译产物，不需要纳入版本控制。
