# ts-verilator-caseincomplete-default

复现 Verilator `%Warning-CASEINCOMPLETE: Case values incompletely covered`。

## 复现

```bash
bash run.sh
```

- `logs/warn-CASEINCOMPLETE.log`：2 位 sel 只覆盖 2 个分支、无 default。
- `logs/fix-add-default.log`：补齐 `default` 分支后零告警（组合逻辑也避免推断锁存）。

## 环境

Verilator ≥ 4.0。

## 原始证据

<https://geek-doc.cn/shots/ts-verilator-caseincomplete-default/>
