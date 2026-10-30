# Icarus Verilog invalid module item 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-invalid-module-item.html （上线后生效）

本目录用 Icarus Verilog 13.0 对照四种非法写法：模块作用域里的裸 `if`、裸过程赋值、放到 `endmodule` 后的 `initial`，以及 `if` 条件缺少右括号。`scope_fixed.v` 把组合过程语句收进 `always @*`，`tb_fixed.v` 验证修复后的两种输入。

## 复现

安装 Icarus Verilog 13.0 后，在本目录执行：

```bash
bash run.sh
```

脚本逐个编译错误版本并要求它们失败，再编译、运行修复版本。成功复现的结尾为 `RESULT: four invalid sources rejected; repaired simulation passed`。临时编译产物在系统临时目录中，退出时自动删除。
