# iverilog 模块重复定义报错复现实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-duplicate-module.html

## 文件

- `adder.v`：8 位加法器（被重复编译的模块）。
- `tb_adder.v`：错误版测试台——`` `include "adder.v" `` 之后又和命令行传入的 `adder.v` 撞车。
- `tb_adder_fixed.v`：修复版测试台——去掉 `` `include ``，模块靠文件列表传入。

## 复现

```bash
# 场景 1：命令行把 adder.v 写了两次
iverilog -o simv adder.v tb_adder.v adder.v

# 场景 2：tb 里 `include 了 adder.v，命令行又传一次
iverilog -o simv adder.v tb_adder.v

# 修复：去掉 include、文件列表去重后复跑
iverilog -o simv adder.v tb_adder_fixed.v && vvp simv
```

预期输出 `PASS: 25 + 17 = 42`。

环境：Icarus Verilog 13.0（`iverilog -V` 可查版本）。
