# verilator-lintoff-pragma：lint_off pragma 最小豁免实验

**对应教程**：https://geek-doc.cn/eda/ts-verilator-lintoff-pragma.html（教程上线后生效）

用同一份 `reg_bank.v` 的四个版本演示 `/* verilator lint_off ... */` 的正确用法与滥用后果：

- `step1/`：原始版本，两处位宽告警（一处有意截断、一处真 bug）+ 两处 UNUSED。
- `step2/`：错误示范——文件顶部整片豁免，lint 通过但真 bug 被埋掉。
- `step3/`：正确姿势——只对有意截断的一行做配对豁免，真 bug 告警重新浮出水面。
- `step4/`：修复版——真 bug 修掉 + 显式 unused 汇总，`verilator --lint-only -Wall` 干净通过（exit=0）。

## 复现

```bash
cd step1   # 或 step2 / step3 / step4
docker run --rm -v $PWD:/work -w /work geek-eda:0.2 verilator --lint-only -Wall reg_bank.v
```

本机已装 Verilator 5.020 时直接 `verilator --lint-only -Wall reg_bank.v` 即可。

`run1.log` 是四个版本依次 lint 的完整原始输出（2026-10-29，Verilator 5.020）。
