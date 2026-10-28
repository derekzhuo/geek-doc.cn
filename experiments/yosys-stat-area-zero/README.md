# yosys-stat-area-zero

**对应教程**：https://geek-doc.cn/eda/ts-yosys-stat-area-zero.html

复现 `yosys -p 'synth; stat'` 输出 `Number of cells: 0`（逻辑被全部优化掉）的最小实验。

## 文件

- `bad_no_output.v`：累加器逻辑写全了，但没有输出端口——synth 后 cell 数塌成 0。
- `fixed_with_output.v`：补上 `sum` 输出端口，同样的逻辑保留，synth 后 80 个 cell。

## 复现

```bash
# 现象：cells = 0
yosys -p 'read_verilog bad_no_output.v; synth -top top; stat'

# 定位：proc 前 3 cells / proc 后 5 cells，说明逻辑进过网表、是后续 opt 删掉的
yosys -p 'read_verilog bad_no_output.v; hierarchy -top top; stat; proc; stat'

# 修复后复跑：cells = 80
yosys -p 'read_verilog fixed_with_output.v; synth -top top; stat'
```

环境：Yosys 0.33（docker 镜像 geek-eda:0.2），日期 2026-10-29。
