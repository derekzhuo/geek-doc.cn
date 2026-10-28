# verilator-warn-cmpconst

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-cmpconst.html（上线后生效）

Verilator `%Warning-CMPCONST`（比较条件因操作数取值范围受限而恒为常量）的最小复现与修复对照。

## 文件

- `cmpconst_bad.v`：报错版。8 位自由运行计数器 `cnt` 跟 `8'd255` 做 `>` 比较，`cnt` 最大就是 255，条件恒假，`done` 永远拉不起来。
- `cmpconst_fixed.v`：修复版。改用 `cnt == 8'd255` 判断数满一圈，比较条件可达。
- `run1.log`：完整实验记录（报错 → 修复 → 复跑零告警）。

## 复现

```bash
verilator --lint-only -Wall cmpconst_bad.v    # 触发 %Warning-CMPCONST，exit 1
verilator --lint-only -Wall cmpconst_fixed.v  # 零告警，exit 0
```

实验环境为 Verilator 5.020（docker 镜像 geek-eda:0.2），也可用本机安装的 Verilator 直接跑。
