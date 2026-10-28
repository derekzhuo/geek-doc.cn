# verilator-warn-unusedparam

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-unusedparam.html

Verilator `UNUSEDPARAM`（parameter 声明了但模块内没引用）的最小复现与修复对照。

## 文件

- `unusedparam_bad.v`：复现版——`WIDTH` 在用，`MAX_DEPTH`（重构残留）与 `DEBUG_LEVEL`（调试占位）声明后无人引用。
- `unusedparam_fixed.v`：修复版——删掉两个未使用参数，接口只保留真实在用的 `WIDTH`。
- `run1.log`：完整实测记录（警告原文 → 修复后复跑零警告、退出码 0）。

## 复现

```bash
verilator --lint-only -Wall unusedparam_bad.v    # 报 UNUSEDPARAM x2，退出码 1
verilator --lint-only -Wall unusedparam_fixed.v  # 零警告，退出码 0
```

本实验实测环境为 Verilator 5.020（Debian 5.020-1），其他 5.x 版本行为一致。注意 `UNUSEDPARAM` 只在 `-Wall`（或显式 `-Wwarn-UNUSEDPARAM`）下开启。
