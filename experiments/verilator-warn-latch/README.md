# verilator-warn-latch

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-latch.html（上线后生效）

Verilator `%Warning-LATCH`（组合 always 块分支不全推断出锁存器）的最小复现与修复对照。

## 文件

- `latch_bad.v`：报错版。`always @(*)` 里只有 `if (sel) y = a;`，缺 `else`，`sel==0` 时 `y` 保持旧值，Verilator 推断出 latch。
- `latch_fixed.v`：修复版。补全 `else y = b;`，所有控制路径都有赋值。
- `run1.log`：完整实验记录（报错 → 修复 → 复跑零告警）。

## 复现

```bash
verilator --lint-only -Wall latch_bad.v    # 触发 %Warning-LATCH，exit 1
verilator --lint-only -Wall latch_fixed.v  # 零告警，exit 0
```

实验环境为 Verilator 5.020（docker 镜像 geek-eda:0.2），也可用本机安装的 Verilator 直接跑。
