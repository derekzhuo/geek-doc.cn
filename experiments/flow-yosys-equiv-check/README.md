# flow-yosys-equiv-check

**对应教程**：https://geek-doc.cn/eda/flow-yosys-equiv-check.html

用 Yosys 0.33 的 `equiv_make` / `equiv_simple` / `equiv_status` 三个 pass 做组合逻辑形式等价检查（Combinational Equivalence Checking）的最小实验：

- `golden.v`：带使能的 2-4 译码器（`case` 写法），作为黄金参考；
- `revised.v`：功能等价的移位写法（`4'b0001 << sel`），先 `synth -flatten` 综合再比对，应当 **EQUIVALENT**；
- `buggy.v`：故意把 `en=0` 时输出写成 `4'b0001`，应当 **NOT EQUIVALENT**（y[0] 无法证明）。

## 复现方式

需要本机装有 Docker 与镜像 `geek-eda:0.4-flow`（Yosys 0.33，含 SAT 后端）。

```bash
make run        # 顺序跑版本号、等价例(eq.ys)、不等价例(neq.ys)
make eq         # 只跑等价例
make neq        # 只跑不等价例（equiv_status 不使用 -assert，退出码仍为 0）
```

`eq.ys` 末尾是 `equiv_status -assert`，等价时退出码 0；把脚本中的 golden/revised 换成你自己的设计即可套用。`neq.ys` 故意不加 `-assert`，便于看到 `1 unproven $equiv cell` 的完整报告而不中断脚本。

## 文件说明

| 文件 | 作用 |
|------|------|
| `golden.v` | 黄金参考 RTL（always + case） |
| `revised.v` | 等价改写 RTL（assign + 移位） |
| `buggy.v` | 含一处功能错误的版本 |
| `eq.ys` | 等价例 Yosys 脚本（golden RTL vs revised 综合后网表） |
| `neq.ys` | 不等价例 Yosys 脚本 |
| `run.sh` | 容器内连续跑两例并打印退出码 |
