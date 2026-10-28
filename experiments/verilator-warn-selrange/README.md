# verilator-warn-selrange

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-selrange.html

Verilator `%Warning-SELRANGE`（位选/部分选择下标越界）最小复现与修复对照。

## 文件

- `selrange_bad.v`：触发 SELRANGE 的错误版（常量位选 `data[8]`、可变下标 `data[idx]` 超宽、部分选择 `data[9:6]` 越界）。
- `selrange_fixed.v`：修复版（下标回到合法范围、可变下标先判界再取位）。

## 复现

```bash
verilator --lint-only -Wall selrange_bad.v    # 报 SELRANGE 等 4 条告警
verilator --lint-only -Wall selrange_fixed.v  # 零告警通过
```

实测环境：Verilator 5.020（2026-10-29）。
