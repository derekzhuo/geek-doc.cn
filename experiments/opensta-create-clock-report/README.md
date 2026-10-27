# OpenSTA create_clock 与 report_checks 最小闭环（opensta-create-clock-report）

**对应教程**：https://geek-doc.cn/chip-design/beginner/opensta-create-clock-report.html（上线后生效）

最小 STA 闭环：sky130 单元库 + 一个综合后的寄存器级网表，`create_clock` 10ns 后 `report_checks` 出完整 setup 报告，slack 8.76 MET。

## 文件

- `sta_demo.v` —— 被测 RTL（含两级寄存器与组合逻辑）
- `run.tcl` —— STA 脚本：read_liberty / read_verilog / link_design / create_clock / report_checks
- `output/netlist-synth.log` —— yosys 综合产网表日志
- `output/report.log` —— 完整 setup 检查报告

## 实验环境

- Ubuntu 22.04 + Yosys 0.9 + OpenSTA 2.4.0（OpenLane docker 镜像内 `/build/bin/sta`）
- 单元库：sky130_fd_sc_hd tt_025C_1v80（volare 安装的 sky130A PDK）

## 复现

```bash
# ① yosys 综合出门级网表（LIB 指向 sky130_fd_sc_hd__tt_025C_1v80.lib）
yosys -p "read_verilog sta_demo.v; synth -top sta_demo; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; clean; write_verilog sta_demo_net.v"

# ② OpenLane docker 内跑独立 OpenSTA
sudo docker run --rm -v $PWD:/w -w /w \
  -e STA_LIB=$LIB efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 \
  /build/bin/sta -exit run.tcl
```

注意：用 `openroad` 入口会在 link_design 报 ORD-1010「no technology has been read」（需先 read_lef）；纯 `sta` 入口无需 LEF。

## 关键结果

```
Startpoint: _37_ (rising edge-triggered flip-flop clocked by clk)
Endpoint:   _44_ ...
  1.17   data arrival time
  9.92   data required time
  8.76   slack (MET)
```
