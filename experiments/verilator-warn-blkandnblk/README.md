# Verilator BLKANDNBLK 复现实验

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-blkandnblk.html（上线后生效）

## 文件

- `blkandnblk_bad.v`：最小复现——复位分支用阻塞赋值 `=`、累加分支用非阻塞赋值 `<=`，同一变量 `cnt` 混赋，触发 `%Error-BLKANDNBLK`
- `blkandnblk_fixed.v`：修复版——全量统一为 `<=`，lint 零告警
- `tb_race.v`：行为差异演示 testbench，另一个 `always` 块与 DUT 同沿采样 `cnt`，复现混赋带来的读-写竞争

## 复现

```bash
# 触发 BLKANDNBLK（Verilator 5.020）
verilator --lint-only -Wall blkandnblk_bad.v

# iverilog 行为对照（混赋版被静默接受，复位沿采样值依赖进程调度顺序）
iverilog -g2012 -o tb_race.vvp blkandnblk_bad.v blkandnblk_fixed.v tb_race.v && vvp tb_race.vvp

# 修复版复验，零告警退出码 0
verilator --lint-only -Wall blkandnblk_fixed.v
```
