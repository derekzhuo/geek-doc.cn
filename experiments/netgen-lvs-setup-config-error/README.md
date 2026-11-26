# Netgen LVS setup 配置错误复现

**对应教程**：https://geek-doc.cn/eda/netgen-lvs-setup-config-error.html（上线后生效）

这个最小实验固定两份独立维护的 SPICE 网表，只改变 Netgen setup。两侧拓扑相同，但 MOS 宽度有意不同；教学比较的目标是通过 `property ... remove W` 忽略宽度。坏配置把 `pmos` 写成 `pmos_typo`，好配置只修正这个单元名。

## 环境

- Docker；镜像基于 Ubuntu 24.04，安装 `netgen-lvs` 1.5.133-1.2。
- Ubuntu 的 `netgen` 包是网格生成器，本实验使用电路比较工具 `netgen-lvs`。
- 不使用 PDK，不读取 GDS；结果只说明通用 SPICE 网表与 setup 行为，不代表工艺签核。

## 复现

```bash
make run
```

脚本用同一对输入分别运行坏配置和好配置，并自动检查坏配置的 `No such cell`、`Property errors were found` 及 2.2u/2u 宽度差异；随后检查修复报告唯一匹配、引脚等价且没有 setup 或属性错误。预期末尾为：

```bash
BAD: No such cell and Property errors were found (expected)
GOOD: Netlists match uniquely; no setup or property errors
PASS: correcting pmos_typo to pmos removes the original failure
```

Netgen 1.5.133 在忽略 setup 行错误后仍可能返回退出码 0，不能只靠 shell 退出状态判断成败。完整核心命令为：

```bash
netgen-lvs -batch lvs \
  "netlists/layout.spice chip" "netlists/schematic.spice chip" \
  setup/good.tcl results/good.out
```

## 文件

| 路径 | 内容 |
|---|---|
| `netlists/layout.spice` | 版图侧教学网表，宽度有意不同 |
| `netlists/schematic.spice` | 独立维护的原理图侧网表 |
| `setup/bad.tcl` | 含 `pmos_typo` 的错误配置 |
| `setup/good.tcl` | 修正单元名后的配置 |
| `run.sh` | 两次比较及自动断言 |
| `results/bad.out` | 错误配置的完整 LVS 报告 |
| `results/bad.stdout.log` | 错误配置的过程诊断 |
| `results/good.out` | 修复后的完整 LVS 报告 |
| `results/good.stdout.log` | 修复后的过程日志与终判 |
| `results/version.log` | Netgen 版本原文 |
| `results/verification.log` | 自动断言摘要 |

`make clean` 只删除重新生成的结果。这里的 `remove W` 是教学用故意宽松策略；真实项目是否能忽略宽度必须由器件模型、比较目标和签收规则决定，不能照搬。
