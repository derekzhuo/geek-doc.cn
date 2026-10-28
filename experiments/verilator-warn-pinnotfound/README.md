# verilator-warn-pinnotfound

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-pinnotfound.html

Verilator `%Error-PINNOTFOUND: Pin not found` 最小复现：例化 `adder` 时把端口名写成模块定义里不存在的 `data_a`。

## 文件

- `adder.v`：被例化的子模块，真实端口为 `a/b/cin/sum/cout`
- `top_bad.v`：报错版，例化时写成 `.data_a(x)`
- `top_fixed.v`：修复版，改回 `.a(x)`
- `run1.log`：报错复现 → 修复 → 复跑通过的完整 lint 实录（Verilator 5.020）

## 复现

```bash
verilator --lint-only -Wall --top-module top_bad top_bad.v adder.v    # 报 PINNOTFOUND，退出码 1
verilator --lint-only -Wall --top-module top_fixed top_fixed.v adder.v  # 零告警，退出码 0
```
