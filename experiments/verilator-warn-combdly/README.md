# verilator-warn-combdly

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-combdly.html

Verilator `%Warning-COMBDLY` 最小复现与修复对照。

## 文件

- `combdly_real.v`：报错版——组合 `always @(*)` 块里用非阻塞赋值 `<=`，触发 `%Warning-COMBDLY`。
- `combdly_real_fixed.v`：修复版——组合逻辑改用阻塞赋值 `=`，lint 干净。
- `combdly_bad.v`：对照样——组合块里写 `#5` 延时，Verilator 5.020 下报的是 `%Error-NEEDTIMINGOPT` / `%Warning-STMTDLY`，与 COMBDLY 是两个不同的告警族（正文有辨析）。

## 复现

```bash
verilator --lint-only -Wall combdly_real.v        # 报 COMBDLY，exit 1
verilator --lint-only -Wall combdly_real_fixed.v  # 零告警，exit 0
verilator --lint-only -Wall combdly_bad.v         # 报 NEEDTIMINGOPT（# 延时族）
```

实测环境：Verilator 5.020 2024-01-01。
