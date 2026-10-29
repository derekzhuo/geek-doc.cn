# Yosys 模块重复定义最小复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-duplicate-module-definition.html（上线后生效）

本例用两个同名但逻辑不同的 `pulse` 模块复现 Yosys 的 `Re-definition of module` 错误，并对照同文件重复传入、`-defer`、`-lib`、文件去重和模块改名六种情况。

## 文件

- `top.v`：例化 `pulse` 的顶层。
- `pulse_a.v`：与门实现。
- `pulse_b.v`：同名或门实现，用于触发冲突。
- `top_fixed.v`、`pulse_or.v`：改名后的可综合版本。
- `run.sh`：依次运行六个用例并核对预期退出码。
- `run1.log`：Yosys 0.33 的合并标准输出与标准错误记录。

## 复现

已安装 Yosys 时直接运行：

```bash
bash run.sh
```

没有本地 Yosys、但有 Docker 时，脚本会使用 `geek-eda:0.2`。需要保存完整记录时：

```bash
bash run.sh 2>&1 | tee run1.log
```

脚本预期普通冲突、重复输入和 `-defer` 三个用例退出码为 1；`-lib` 用例退出码为 0，但会报告替换已有黑盒；去重与改名版本都经过 `hierarchy -check`、`synth -noabc` 和 `check -assert`，退出码为 0。全部符合预期时输出 `PASS`。
