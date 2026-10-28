# iverilog inout 端口连接错误复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-inout-connect.html

## 文件

- `inout_bad.v`：错误示范——`inout` 端口连接到 `reg`，iverilog 13.0 编译期报 `Inout port expression must support continuous assignment`。
- `inout_fixed.v`：修复版——`reg` 改 `wire`，双向驱动都走三态（`'z` 让出总线）。
- `run1.log`：报错 → 修复 → 复跑的完整原始记录（Icarus Verilog 13.0）。

## 复现

```bash
iverilog -g2005 -o inout_bad.vvp inout_bad.v      # 复现 3 条 error，exit 3
iverilog -g2005 -o inout_fixed.vvp inout_fixed.v  # 编译通过
vvp inout_fixed.vvp                               # 仿真输出 PASS
```
