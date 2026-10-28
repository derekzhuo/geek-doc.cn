# verilator-warn-realcvt

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-realcvt.html

Verilator `%Warning-REALCVT`（real 到整数的隐式转换）最小复现与定点化修复。

## 文件

- `gain_bad.v`：触发告警版——增益系数 `3.7` 是 real 字面量，乘积隐式转回整数。
- `gain_fixed.v`：定点化修复版——3.7 用 Q1.6 定点常数 237 表示，全整数运算。
- `tb.v`：Icarus 仿真对照两版输出误差。

## 复现

```bash
verilator --lint-only -Wall gain_bad.v     # 复现 %Warning-REALCVT
iverilog -g2012 -o tb.vvp gain_bad.v gain_fixed.v tb.v && vvp tb.vvp
verilator --lint-only -Wall gain_fixed.v   # 修复后零告警
```

环境：Verilator 5.020（geek-eda:0.2 docker 镜像）、Icarus Verilog 13.0。
