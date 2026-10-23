# ts-iverilog-unknown-module-type：iverilog "Unknown module type" 复现实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-unknown-module-type.html

## 复现

```sh
sh run.sh
```

脚本分两步：

1. 只编译顶层 `top_use_adder.v`（漏传子模块）→ 触发 `error: Unknown module type: sub_adder`，exit=2；
2. 把 `sub_adder.v` 补进命令行 → 编译通过，`vvp` 运行输出 `sum=42`。

## 文件

- `top_use_adder.v`：顶层，例化 `sub_adder`；
- `sub_adder.v`：子模块定义（报错场景下故意不传它）。

环境：Icarus Verilog 11+（实测 13.0）。
