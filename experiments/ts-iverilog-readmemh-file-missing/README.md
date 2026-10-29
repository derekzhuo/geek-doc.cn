# Icarus Verilog `$readmemh` 相对路径与文件格式对照实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-readmemh-file-missing.html（上线后生效）

本实验用 Icarus Verilog 复现四种情况：指定文件不存在、从正确工作目录运行、从错误工作目录运行同一个仿真文件，以及 hex 文件存在但含非法字符。测试平台会检查四个存储单元，避免只凭运行时警告判断结果。

## 复现

安装 `iverilog` 与 `vvp` 后，在本目录运行：

```bash
bash run.sh
```

脚本合并标准输出和标准错误，逐项打印实际与预期退出码。缺文件、错误工作目录和非法 hex 三组预期失败，正确路径组预期通过；所有结果符合预期时，脚本最后打印总 PASS 并退出 0。

## 文件

- `broken/tb_readmemh.sv`：读取不存在的 `data/not-present.hex`。
- `fixed/tb_readmemh.sv`：读取 `data/pattern.hex`，必须从本目录启动仿真。
- `malformed/tb_readmemh.sv`：读取存在但含 `GG` 的 `data/malformed.hex`。
- `run1.log`：Icarus Verilog 13.0 的原始对照输出。

生成的 `build/` 只含临时仿真文件，可随时删除。
