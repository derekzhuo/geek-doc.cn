# Verilator TIMESCALEMOD 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-timescalemod.html（上线后生效）

本目录用两个跨文件模块复现：顶层声明 `timescale 1ns/1ps`，叶子模块缺少声明。测试在 0.5ns 检查脉冲仍为低，在 1.5ns 检查脉冲已经升高，因此叶子模块的 `#1` 必须解释为 1ns。

## 目录

- `broken/`：叶子模块缺少 `timescale`，用于复现 `TIMESCALEMOD`。
- `fixed/`：两个模块都显式声明 `timescale 1ns/1ps`。
- `run.sh`：依次执行缺省 lint、修复 lint、缺省仿真、修复仿真和强制 1ps 的反例。
- `run1.log`：Verilator 5.020 的完整原始输出。

## 复现

在安装 Docker 且存在 `geek-eda:0.2` 镜像的环境中，进入本目录执行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run
```

`TIMESCALEMOD` 在该版本默认不启用，所以 lint 命令显式加入 `-Wwarn-TIMESCALEMOD`。缺省文件排在有声明文件之前，使缺省模块没有可继承的前置指令。脚本预期缺省 lint 退出 1、修复 lint 退出 0；修复仿真输出 PASS，强制全工程使用 1ps 的反例在 0.5ns 检查点失败并退出 134。所有预期满足时，脚本最终输出 PASS 并退出 0。

生成的 C++ 和可执行文件位于 `build/`，可执行 `make clean` 删除。
