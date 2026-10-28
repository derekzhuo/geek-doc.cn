# verilator-warn-initialdly

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-initialdly.html（上线后生效）

Verilator 对 `initial` 块中 `#` 延时与非阻塞赋值的告警复现与修复示例（Verilator 5.020）。

## 文件

- `initdly_bad.v`：`initial` 块里用 `#10`/`#5` 延时做复位释放（报错复现版）
- `initdly_nba.v`：`initial` 块里用带延时的非阻塞赋值 `<= #10`（触发 INITIALDLY 告警）
- `initdly_fixed.v`：修复版——改用计数器 + 时钟沿释放复位
- `run1.log`：完整 lint 实录（报错 → 修复 → 复跑通过）

## 复现

```bash
verilator --lint-only -Wall initdly_bad.v            # 5.020 默认报 NEEDTIMINGOPT 错误
verilator --lint-only -Wall --no-timing initdly_bad.v  # --no-timing 下报 STMTDLY 告警
verilator --lint-only -Wall --no-timing initdly_nba.v  # 触发 INITIALDLY 告警
verilator --lint-only -Wall initdly_fixed.v          # 修复版零告警通过
```
