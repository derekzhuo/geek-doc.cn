# flow-opensta-clock-gating-check

**对应教程**：https://geek-doc.cn/eda/flow-opensta-clock-gating-check.html

OpenSTA 2.0.17 时钟门控检查（clock gating check）最小可复现实验：用自写教学 liberty（BUF_X1 / BUF_D1 / AND2_X1 / DFF_X1，标量延时，不对应任何真实工艺，产线请替换为 PDK 签核库）搭出门控时钟网表，对照「无 set_clock_gating_check（推断 0 值检查）/ 写入 ICG 库检查值 / EN 路径被拉长到 setup 违例」三种情形。

## 文件

- `teaching.lib`：教学最小库（AND2_X1 作门控单元，使能端为 B，时钟端为 A）；库结构与阈值写法复用自同仓 `flow-opensta-multi-corner/ss.lib`，新增 AND2_X1、BUF_D1 两个单元。
- `top.v`：EN 触发器 u_enff → BUF_X1 → AND2_X1(B)，clk → AND2_X1(A) → gclk → u_dff。
- `top_slow.v`：EN 路径插入两级 BUF_D1（每级 1.60ns），制造门控 setup 违例。
- `case_a_nocmd.tcl` / `case_b_check.tcl` / `case_c_slow.tcl`：三组对照脚本。
- `help_gating.tcl`：打印 set_clock_gating_check 与 report_checks 的真机 help。

## 复现

```bash
make run
# 等价于：
# docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow bash run.sh
```

本机装有 OpenSTA 2.0.17 时也可直接 `bash run.sh`。
