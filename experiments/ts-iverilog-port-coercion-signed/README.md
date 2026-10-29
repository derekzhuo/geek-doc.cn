# Icarus Verilog 端口 signed 转换对照实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-port-coercion-signed.html （上线后生效）

本实验比较无符号 `raw_code` 直接连接 signed 端口与通过 `$signed(raw_code)` 显式连接的结果。两个用例使用相同的 `8'hff` 位型；修复版用断言检查位型、十进制解释和负数比较。

## 复现

需要 Icarus Verilog，进入本目录执行：

```bash
bash run.sh
```

`bad.sv` 展示隐式端口解释，`fixed.sv` 展示显式转换和自动断言，`run1.log` 保存本次完整实测输出。生成的 `bad_simv`、`fixed_simv` 是临时仿真产物，不需要提交。
