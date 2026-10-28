# iverilog-numeric-truncation

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-numeric-truncation.html（教程上线后生效）

复现 Icarus Verilog 数值字面量位宽截断（老版本报 `warning: Numeric constant truncated to X bits`，13.0 静默吞掉）的最小实验。

## 文件

- `trunc_demo.v`：`reg [7:0]` 赋 9 位字面量 `9'h1FF`、`reg [3:0]` 赋 `5'd17`，仿真打印截断后的错误值。
- `trunc_demo_fixed.v`：字面量位宽与声明对齐、真需要大数就扩声明位宽，复跑自检 PASS。

## 复现

```bash
iverilog -Wall -o trunc_demo trunc_demo.v   # 13.0 无告警，静默通过
vvp trunc_demo                              # x = 255（本想要 511），值已错
verilator --lint-only -Wall trunc_demo.v    # 报 WIDTHTRUNC，直接退出非零
iverilog -Wall -o trunc_demo_fixed trunc_demo_fixed.v
vvp trunc_demo_fixed                        # RESULT: PASS
```

环境：Icarus Verilog 13.0；Verilator 5.020（geek-eda:0.2 docker 镜像）。
