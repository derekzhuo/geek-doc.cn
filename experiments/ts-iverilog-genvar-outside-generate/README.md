# Icarus Verilog genvar 与 generate 错误最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-genvar-outside-generate.html（上线后生效）

本目录包含两个对照示例：用 `integer` 驱动生成期循环会报错；在模块中省略 `generate/endgenerate` 则被 Icarus Verilog 13.0 接受。`fixed_generate.v` 给出显式 generate 的修复版本，`tb_fixed_generate.v` 用运行期 `for` 遍历全部 16 种输入。

## 复现

需要 Icarus Verilog。进入本目录后执行：

```bash
bash run.sh
```

脚本以 `-g2005` 编译两个对照模块：错误示例预期退出码非 0，省略 generate 的对照预期退出码为 0；随后编译并仿真修复模块，预期编译与仿真退出码均为 0，末尾输出总 PASS。`.vvp` 是本地编译产物，可随时删除。

`run1.log` 保存了本文使用的 Icarus Verilog 13.0 原始运行记录。
