# iverilog 宏未定义报错（macro undefined）复现与修复

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-undefined-macro.html（上线后生效）

最小复现 Icarus Verilog 13.0 的 `warning: macro BUS_W undefined (and assumed null)`：用了没定义的宏只是警告而非错误，宏被假设为空串，8 位总线静默降级成 `[-1:0]` 两位向量。

## 文件

- `demo_bad.v`：最小复现——使用未定义的 `` `BUS_W `` 作端口宽度。
- `defs.vh` + `demo_fixed.v`：修复版——`` `include `` 宏定义文件后再使用宏。
- `defs_order.v` + `demo_order.v`：场景 B——宏定义在另一个文件里，命令行文件顺序决定宏是否可见。
- `run1.log`：完整实验记录（复现 → 修复 → 复跑）。

## 复现

```bash
# 复现 warning（exit=0，编译照过，坑在这）
iverilog -o demo_bad.vvp demo_bad.v

# 看预处理后真实展开的代码：宽度变成 [-1:0]
iverilog -E -o bad_pp.v demo_bad.v && sed -n '3p;4p;7p' bad_pp.v

# 场景 B：命令行顺序错，定义文件排在后面
iverilog -o order_bad.vvp demo_order.v defs_order.v

# 修复 1：定义文件放前面
iverilog -o order_ok.vvp defs_order.v demo_order.v

# 修复 2：-D 传参
iverilog -DBUS_W=8 -o demo_bad.vvp demo_bad.v

# 修复 3：`include 宏定义文件
iverilog -o demo_fixed.vvp demo_fixed.v
vvp demo_fixed.vvp
```
