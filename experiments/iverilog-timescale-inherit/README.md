# iverilog timescale 继承警告复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-timescale-inherit.html

## 文件

- `tb.v` —— 带 `` `timescale 1ns/1ps `` 的测试台（时钟半周期 5ns）
- `dut.v` —— 故意不写 `` `timescale `` 的被测模块（复现用）
- `dut_fixed.v` —— 修复版，补上 `` `timescale 1ns/1ps ``
- `run1.log` —— 完整实测记录（Icarus Verilog 13.0，2026-10-29）

## 复现

```bash
# 复现警告：无 timescale 的文件放前面编译
iverilog -o sim_bad dut.v tb.v
vvp sim_bad                    # time=52000 y=0（dut 的 #2 变成 2 秒，功能直接错）

# 定位是哪个模块缺 timescale
iverilog -Wtimescale -o sim_bad dut.v tb.v

# 修复后复跑：零警告，功能正确
iverilog -o sim_ok tb.v dut_fixed.v
vvp sim_ok                     # time=52000 y=1
```

要点：iverilog 里没写 `` `timescale `` 的模块会吃到「默认时间单位」（1s/1s），和带 `` `timescale `` 的文件混编时 `#delay` 的实际单位不一致，仿真波形悄悄错位。
