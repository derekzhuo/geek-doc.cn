# yosys-warning-multiple-drivers

**对应教程**：https://geek-doc.cn/eda/ts-yosys-warning-multiple-drivers.html

Yosys `Warning: multiple conflicting drivers` 的最小复现与修复对照。

## 文件

- `multi_drv_bad.v`：复现用例——同一个 `reg y` 被一个时序 always 块和一个组合 always 块同时驱动。
- `multi_drv_fixed.v`：修复版——合并为单个时序 always 块，块内用 `sel` 显式表达选择意图。

## 复现

```bash
yosys -p 'read_verilog multi_drv_bad.v; hierarchy -top multi_drv_bad; proc; check'
# 期望：8 条 "Warning: multiple conflicting drivers"，Found and reported 8 problems

yosys -p 'read_verilog multi_drv_fixed.v; hierarchy -top multi_drv_fixed; proc; check'
# 期望：Found and reported 0 problems
```

实测环境：Yosys 0.33（docker 镜像 geek-eda:0.2）。
