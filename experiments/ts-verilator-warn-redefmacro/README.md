# Verilator REDEFMACRO 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-redefmacro.html（上线后生效）

用 Verilator 5.020 复现宏值冲突，并验证 include guard 与 `pragma once` 两种修复。

## 目录

- `broken/`：无 include guard，同一头文件经两条路径重复包含，宏值相同。
- `broken_conflict/`：头文件把 `DATA_W` 定义为 8，顶层又定义为 16，触发 REDEFMACRO。
- `fixed_guard/`：传统 include guard 修复。
- `fixed_pragma/`：`pragma once` 修复。
- `logs/run1.log`：Docker `geek-eda:0.2` 中的合并输出记录。

## 复现

已安装 Verilator 的 Linux 环境可直接执行：

```bash
bash run.sh
```

也可使用同一容器镜像：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本预期：默认参数和显式启用 REDEFMACRO 的冲突用例退出码均为 1；同值重复包含退出码为 0；两个修复用例退出码均为 0；最后输出 PASS。
