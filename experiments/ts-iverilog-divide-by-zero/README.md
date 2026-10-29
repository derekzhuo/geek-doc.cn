# Icarus Verilog 除零与除数保护实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-divide-by-zero.html（上线后生效）

本目录包含常量除零、变量除零、x 传播以及带有效位保护的最小实验。

## 复现

安装 Icarus Verilog 后，在本目录执行：

```bash
bash run.sh
```

脚本依次编译并运行 `bad.sv` 与 `fixed.sv`，把标准输出和标准错误合并写入 `run1.log`。坏例用四态断言确认预期中的 x；修复版验证零除数被拦截、正常除法保持原结果。

本文实测记录保存为 `run1.log`，工具版本为 Icarus Verilog 13.0。这里只验证仿真行为，不包含综合实验。
