# 4 位 ALU 的 iverilog 穷举自检查

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-iverilog-alu-self-check.html（教程上线后生效）

这个小实验用独立 Python 整数模型生成全部期望向量，再由 Icarus Verilog testbench 驱动 RTL，并逐项比较结果 R 与 N/Z/C/V。它展示的不是「打印几个值看看」，而是可重复的反例定位、故障检出和修复复跑。

## 本实验的操作约定

| op | 操作 | R | C | V |
|---|---|---|---|---|
| 0 | ADD | `(A+B) mod 16` | 无符号和是否大于 15 | 有符号和是否超出 -8..7 |
| 1 | SUB | `(A-B) mod 16` | 1 表示无符号无借位，即 A>=B | 有符号差是否超出 -8..7 |
| 2 | AND | `A & B` | 0 | 0 |
| 3 | OR | `A \| B` | 0 | 0 |
| 4 | XOR | `A ^ B` | 0 | 0 |

N 始终等于 R[3]，Z 在 R 等于 0 时为 1。以上是本实验局部约定，不宣称与任意 ISA 的标志极性相同。

## 复现

依赖 Python 3、Icarus Verilog（`iverilog` 与 `vvp`）和 Bash。在本目录运行：

```bash
./run.sh
```

脚本依次执行：

1. 用 `gen_vectors.py` 生成 5×16×16=1280 条穷举向量和 6 条关键展示向量。
2. 用 `INJECT_SUB_CARRY` 编译故障版，把 SUB 的 C 错接为最高进位的反相信号。
3. 确认仿真在 1280 条中报告 256 条失败、首个反例为 SUB/0/0，且进程退出码非零。
4. 不定义故障宏，重新编译正确 RTL，确认 1280 条全部通过。
5. 运行 6 条关键向量并生成 `results/selected.vcd`。

任何预期不一致都会让脚本失败；故障版非零退出是预期证据，不会被误当成整个复跑成功。

## 文件

- `alu4.v`：4 位组合 ALU，故障宏只切换 SUB 的 C。
- `gen_vectors.py`：独立参考模型与向量生成器。
- `vectors.txt`、`wave_vectors.txt`：生成后的输入及期望 R/N/Z/C/V。
- `alu4_tb.v`：读取穷举向量，统计全部差异，保留前 8 个反例。
- `wave_tb.v`：复跑 6 条关键向量并输出 VCD。
- `run.sh`：完整故障注入、恢复与复验流程。
- `results/`：真实运行日志和关键向量 VCD。

## 已记录结果

运行环境为 x86_64 macOS 26.5.2、Icarus Verilog 13.0、Python 3.15.2。`results/run.log` 保留了工具版本、完整命令、故障版的 256 个失败计数、正确版 `PASS vectors=1280 failures=0`，以及关键向量 `WAVE PASS vectors=6 failures=0`。
