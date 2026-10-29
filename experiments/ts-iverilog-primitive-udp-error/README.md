# iverilog UDP 原语非法表项复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-primitive-udp-error.html（上线后生效）

这个最小实验复现两输入组合 UDP 的表项误写为三个输入符号，并用修复后的 UDP 与 `always @(*)` 实现跑四组二值向量自检。

## 文件

- `udp_bad.v`：非法表项，最后一行有 3 个输入符号，但原语只有 2 个输入端口。
- `udp_fixed.v`：修正为每行 2 个输入符号，并封装成 `and2_udp`。
- `and2_always.v`：同一二输入与逻辑的 `always @(*)` 对照实现。
- `tb_and2.v`：遍历 `00`、`01`、`10`、`11`，同时核对预期值和两种实现。
- `run1.log`：Icarus Verilog 13.0 的原始合并输出。

## 复现

需要 `iverilog` 与 `vvp`，在本目录执行：

```bash
bash run.sh
```

脚本预期非法版本编译退出码为 1；修复版编译和仿真退出码均为 0，测试平台打印 `PASS: 4/4 binary vectors match`。自检只覆盖四个二值输入组合，不声明未知态等价或综合结果。
