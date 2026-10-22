# ts-verilator-width-mismatch-WIDTH

复现 Verilator `%Warning-WIDTH: ... 12-bit assignment ... from 4-bit signal`。

## 复现

```bash
bash run.sh
```

- `logs/warn-WIDTH.log`：12 位左值直接赋 4 位右值，`-Wall` 下 WIDTH 告警。
- `logs/fix-zero-warning.log`：`{8'b0, a}` 显式零扩展后零告警。

## 环境

Verilator ≥ 4.0（`apt install verilator` / `brew install verilator`）。

## 原始证据

<https://geek-doc.cn/shots/ts-verilator-width-mismatch-WIDTH/>
