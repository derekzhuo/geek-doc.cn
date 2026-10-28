# AXI4 时序逐拍走查（axi4-timing-waveform-walkthrough）

**对应教程**：https://geek-doc.cn/chip-design/intermediate/axi4-timing-waveform-walkthrough.html（上线后生效）

用 Icarus Verilog 仿真一个最小 AXI4-Full 主从对：testbench 作为主端发起一次 4-beat INCR 写突发（起始地址 0x40）和一次 4-beat 读突发，从端（axi4_slave）按协议逐拍应答，TB 逐拍比对数据并检查 BRESP/RLAST。

## 文件

- `axi4_slave.v` —— 最小 AXI4-Full 从端，支持 INCR 突发，内部一块简单存储
- `tb_axi4.v` —— 主端 testbench，驱动 AW/W/B/AR/R 五通道并逐拍自检
- `output/sim.log` —— 实测仿真日志（PASS）

## 实验环境

- Ubuntu 22.04 + Icarus Verilog 11.0（开源 EDA 链路，下同）

## 复现

```bash
iverilog -g2012 -o axi4_tb.out tb_axi4.v axi4_slave.v
vvp axi4_tb.out            # 同时产出 axi4.vcd 波形
```

## 关键结果

仿真 PASS：写突发 BRESP=OKAY，读突发 4 拍数据 `a5a50001`~`a5a50004` 逐一比对一致，末拍 RLAST 正确举起：

```bash
WRITE burst done: BRESP=OKAY at 105000
READ beat 0: rdata=a5a50001 OK at 135000
READ beat 3: rdata=a5a50004 OK at 165000
TB_RESULT: PASS (write+read burst, 4 beats each)
```
