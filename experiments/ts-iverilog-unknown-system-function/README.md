# Icarus Verilog unknown system function 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-unknown-system-function.html （上线后生效）

本目录对比 `$fopne` 拼写错误与正确的 `$fopen`。`broken_typo.v` 可通过编译，但 `vvp` 启动时会报系统函数未定义，`fixed_typo.v` 应编译并运行成功。

## 复现

需要 Icarus Verilog（本记录在 13.0 stable 上验证）：

```bash
bash run.sh
```

脚本合并标准输出与标准错误，分别记录错误版和修复版的退出码，并在结束后删除生成的 `.vvp` 文件。`run1.log` 是本次运行的完整记录。
