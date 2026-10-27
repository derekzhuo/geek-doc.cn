# STA setup 检查原理：逐行读一份完整报告（sta-setup-check-principle-opensta）

**对应教程**：https://geek-doc.cn/chip-design/beginner/sta-setup-check-principle-opensta.html（上线后生效）

用 `report_checks -path_delay max -format full` 产出一份逐行完整的 setup 检查报告：发射沿、clock network delay、逐级单元延迟（dfxtp→and4→nand4→or3→a21boi）、data arrival 2.82、捕获沿 10.00、reconvergence pessimism、library setup -0.08、data required 9.92、slack 7.11 MET——教程逐行解读这份报告的每一行是怎么算出来的。

## 文件

- `sta_demo.v` —— 被测 RTL（与 create_clock 实验同一设计）
- `run.tcl` —— create_clock 10ns + input/output delay + full 格式 report_checks
- `output/report.log` —— 完整 setup 报告（教程逐行解读的对象）

## 实验环境

- Ubuntu 22.04 + Yosys 0.9 + OpenSTA 2.4.0（OpenLane docker 镜像内 `/build/bin/sta`），sky130_fd_sc_hd tt_025C_1v80

## 复现

```bash
# 先综合网表（同 create_clock 实验①）
yosys -p "read_verilog sta_demo.v; synth -top sta_demo; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; clean; write_verilog sta_demo_net.v"

sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run.tcl
```

## 关键结果

报告逐行齐全：data arrival time 1.17（发射沿 + clock network delay + 五级单元延迟累加），data required time 9.92（捕捉沿 10.00 - library setup 0.08，含 reconvergence pessimism 修正），slack = 9.92 - 1.17 = 8.76 MET。
