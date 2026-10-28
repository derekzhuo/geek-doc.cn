# Verilator VARHIDDEN 变量遮蔽警告复现实验

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-varhidden.html

最小复现 `%Warning-VARHIDDEN: Declaration of signal hides declaration in upper scope: 'i'` 警告及修复。

## 文件

- `varhidden_bad.v`：复现版——for 循环变量 `int i` 遮蔽模块级 `integer i`，触发 VARHIDDEN
- `varhidden_fixed.v`：修复版——循环变量改名 `bit_i`，零警告
- `run1.log`：实测完整记录（警告 → 修复 → 复跑）

## 复现

```bash
verilator --lint-only -Wall varhidden_bad.v     # 出现 VARHIDDEN 警告并退出失败
verilator --lint-only -Wall varhidden_fixed.v   # 零警告，退出码 0
```

实测环境为 Verilator 5.020（Debian 打包版），输出见 `run1.log`。
