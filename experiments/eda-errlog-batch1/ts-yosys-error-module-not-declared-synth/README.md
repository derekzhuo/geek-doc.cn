# ts-yosys-error-module-not-declared-synth

复现 Yosys 综合期 `ERROR: Module \`sub_adder' referenced in module \`top_use_adder' is not declared!`。

## 复现

```bash
bash run.sh
```

- `logs/err-missing-submodule.log`：只读顶层文件，例化的子模块未读入。
- `logs/fix-read-all.log`：`read_verilog` 一次列出全部源文件后通过。

根因不是模块没写，而是**没被读进这一轮 Yosys 会话**：多文件工程要把全部
`.v` 列全（或用 `read_verilog $(find rtl -name '*.v')`）。

## 环境

Yosys ≥ 0.9。

## 原始证据

本目录 `evidence/`（原始日志，与教程内嵌摘录同源）
