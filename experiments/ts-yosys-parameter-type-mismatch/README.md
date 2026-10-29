# Yosys 字符串参数静默转换复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-parameter-type-mismatch.html（上线后生效）

本实验验证 Yosys 0.33 对 `parameter integer WIDTH = 8` 被 `.WIDTH("8")` 覆盖时的真实行为：编译不报错，字符串按 ASCII 位型变成 `8'00111000`，即十进制 56；修复版改用 `.WIDTH(8)`，并由 `$clog2(WIDTH)` 派生 3 位索引宽度。

## 文件

- `param_string_bad.v`：字符串覆盖整型参数，得到 56 位总线。
- `param_fixed.v`：显式数值参数，得到 8 位总线与 3 位索引。
- `run.sh`：运行两组 Yosys 检查，并 grep 断言关键参数值与线网位宽。
- `run1.log`：2026-10-30 的完整原始输出，合并标准输出与标准错误。

## 复现

需要 Docker 与 `geek-eda:0.2` 镜像，在本目录执行：

```bash
chmod +x run.sh
./run.sh
```

末尾应出现 `BAD_EXIT=0`、`FIX_EXIT=0` 和一行 `PASS`。这里的 PASS 表示脚本观察到了预期的坏例位宽与修复位宽，并不表示坏例设计正确。可通过 `YOSYS_IMAGE` 环境变量改用其他包含 Yosys 的镜像。
