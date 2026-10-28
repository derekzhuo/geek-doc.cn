# verilator-warn-pinmissing

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-pinmissing.html

Verilator `%Warning-PINMISSING` 最小复现：子模块 `adder` 有 5 个端口，顶层例化时漏接 `cin`。

## 复现

```bash
docker run --rm -v .:/work -w /work geek-eda:0.2 verilator --lint-only -Wall --top-module top_bad adder.v top_bad.v
# 期望：%Warning-PINMISSING: top_bad.v:8:9: Cell has missing pin: 'cin'
```

## 修复后复验

```bash
docker run --rm -v .:/work -w /work geek-eda:0.2 verilator --lint-only -Wall --top-module top_fixed adder.v top_fixed.v
# 期望：零告警，exit 0
```

## 文件

- `adder.v`：子模块（8 位带进位加法器，5 端口）
- `top_bad.v`：报错版顶层，例化漏接 `.cin`
- `top_fixed.v`：修复版顶层，显式 `.cin(1'b0)`
- `run1.log`：2026-10-29 在 Verilator 5.020（geek-eda:0.2 docker）上的完整 lint 输出
