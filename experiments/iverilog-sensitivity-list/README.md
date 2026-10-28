# iverilog-sensitivity-list

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-sensitivity-list.html

组合逻辑 `always` 块敏感表漏信号的最小复现：2-to-4 译码器的敏感表只写了 `a` 漏了 `b`，仿真中 `b` 变化时输出不更新（不报错），而综合器忽略敏感表按表达式补全——经典的 sim/synth mismatch。

## 文件

- `decoder_bug.v`：敏感表漏 `b` 的错误版本（`always @(a)`）
- `decoder_fix.v`：修复版本（`always @(*)`）
- `tb_decoder.v`：测试台，固定 `a=1` 翻转 `b`，对照两版输出并统计 MISMATCH

## 复现

```bash
iverilog -g2012 -o sim_both decoder_bug.v decoder_fix.v tb_decoder.v
vvp sim_both
```

预期输出：`t=33` 行 bug 版显示 `STALE`，结尾 `BUG-VERSION MISMATCH count=1`、`FIX-VERSION PASS`。

综合对照（可选，需 Yosys）：

```bash
yosys -p 'read_verilog decoder_bug.v; synth -top decoder_bug; stat'
yosys -p 'read_verilog decoder_fix.v; synth -top decoder_fix; stat'
```

两版网表单元统计完全一致（2 个 ANDNOT + 1 个 AND + 1 个 NOR），说明综合器不受敏感表影响。
