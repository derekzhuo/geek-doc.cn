# Verilator CASEOVERLAP 分支重叠复现实验

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-caseoverlap.html（上线后生效）

## 内容

- `decoder_bad.v`：反例，`case` 中 `4'b0011` 出现两次，第二个分支是死代码，Verilator `-Wall` 报 `%Warning-CASEOVERLAP` 并以错误退出。
- `decoder_fixed.v`：修复一——消重，删掉重复的 `4'b0011` 分支，lint 通过。
- `irq_prio.sv`：修复二——重叠是「有意的优先级译码」时改用 SystemVerilog `priority case` 显式声明意图，lint 通过。

## 复现

```bash
docker run --rm -v $PWD:/work -w /work geek-eda:0.2 verilator --lint-only -Wall decoder_bad.v
docker run --rm -v $PWD:/work -w /work geek-eda:0.2 verilator --lint-only -Wall decoder_fixed.v
docker run --rm -v $PWD:/work -w /work geek-eda:0.2 verilator --lint-only -Wall irq_prio.sv
```

本机已装 Verilator 5.x 时直接 `verilator --lint-only -Wall <file>` 即可，无需 docker。
