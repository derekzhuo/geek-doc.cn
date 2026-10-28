# iverilog 端口位宽不匹配警告复现实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-port-width-mismatch.html

最小复现 `Port 1 (a) of module adder8 expects 8 bit(s), given 4` 警告及修复。

## 文件

- `sub.v`：8 位加法器子模块
- `top.v`：复现版——4 位信号接 8 位端口，触发警告
- `top_fixed.v`：修复版——信号位宽对齐 8 位，零警告
- `run1.log`：实测完整记录（警告 → 修复 → 复跑）

## 复现

```bash
iverilog -o simv top.v sub.v && vvp simv        # 出现 Padding high bits 警告
iverilog -o simv_fixed top_fixed.v sub.v && vvp simv_fixed  # 零警告，PASS
```
