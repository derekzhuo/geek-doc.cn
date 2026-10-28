# yosys-read-verilog-include：Yosys include 文件找不到（Can't open include file）复现与修复

**对应教程**：https://geek-doc.cn/eda/ts-yosys-read-verilog-include.html

复现 Yosys `read_verilog` 因 `include` 文件不在搜索路径而报 `ERROR: Can't open include file` 的最小现场，以及用 `-I` 加搜索路径的修复。

## 目录

- `inc/defs.v`：公共宏定义，放在独立子目录里，正是「默认搜不到」的那类文件。
- `rtl/top.v`：顶层模块，`\`include "defs.v"` 引用宏。

## 复现

```bash
yosys -p 'read_verilog rtl/top.v'
# ERROR: Can't open include file `defs.v'!
```

## 修复

```bash
yosys -p 'read_verilog -I inc rtl/top.v; hierarchy -top top; stat'
# Top module: \top，综合出 1 个 $add，零错误
```

多个 include 目录可以叠加多个 `-I`：`read_verilog -I inc -I lib rtl/top.v`。
