# sby-smtbmc-timeout

**对应教程**：https://geek-doc.cn/eda/ts-sby-smtbmc-timeout.html

smtbmc depth 给小导致「界内无结论」，加大 depth 后拿到明确结论（cover/bmc 两种写法对照）。

## 复现

```bash
./run.sh
```

- `cov3.sby`（cover depth 3）：目标第 11 拍才可达 → `Unreached cover statement`，FAIL/无结论。
- `cov12.sby`（depth 12）：`Reached cover statement ... in step 11`，PASS。
- `bound3.sby`（bmc depth 3）：界内无反例的有界 PASS；`bound12.sby`：反例 FAIL + trace.vcd。

## 目录

- `cover.v` / `reach.v`：4 位周期 +1 计数器（cover / assert 两种属性写法）。
- `cov3.sby`、`cov12.sby`、`bound3.sby`、`bound12.sby`、`run.sh`。
