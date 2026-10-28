# yosys-hierarchy-check-fail

**对应教程**：https://geek-doc.cn/eda/ts-yosys-hierarchy-check-fail.html

复现 Yosys `hierarchy -check` 报错 `ERROR: Module 'xxx' referenced in module 'yyy' in cell 'zzz' is not part of the design` 的最小工程。

## 文件

- `top.v`：顶层模块，参数化例化 `fifo #(.WIDTH(8), .DEPTH(16)) u_fifo (...)`。
- `fifo.v`：参数化同步 FIFO 子模块（修复时需要把它一起读入）。

## 复现

```bash
# 1. 报错：只读顶层，fifo 定义缺失，hierarchy -check 失败
yosys -p 'read_verilog top.v; hierarchy -check -top top'
# => ERROR: Module `\fifo' referenced in module `\top' in cell `\u_fifo' is not part of the design.

# 2. 修复：把 fifo.v 一起读入，hierarchy -check 通过并打印层级
yosys -p 'read_verilog fifo.v top.v; hierarchy -check -top top; stat'
```

实测环境：Yosys 0.33（git sha1 2584903a060），docker 镜像 geek-eda:0.2。
