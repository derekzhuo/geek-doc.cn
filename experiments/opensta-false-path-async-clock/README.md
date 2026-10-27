# OpenSTA 异步时钟：set_false_path 与 set_clock_groups 对照（opensta-false-path-async-clock）

**对应教程**：https://geek-doc.cn/chip-design/intermediate/opensta-false-path-async-clock.html（上线后生效）

一个双时钟设计（clk_a 10ns / clk_b 7ns，跨域走两级同步器），分别用 `set_false_path -from clk_a -to clk_b` 和 `set_clock_groups -asynchronous` 两种写法豁免跨域路径，验证两者检查集合效果一致。

## 文件

- `sta_async.v` —— 双时钟 RTL，跨域两级同步器
- `run_false_path.tcl` —— 写法一：set_false_path
- `run_clock_groups.tcl` —— 写法二：set_clock_groups -asynchronous
- `output/false_path.log` / `output/clock_groups.log` —— 两遍报告

## 实验环境

- Ubuntu 22.04 + Yosys 0.9 + OpenSTA 2.4.0（OpenLane docker 镜像内 `/build/bin/sta`），sky130_fd_sc_hd tt_025C_1v80

## 复现

```bash
# 先综合网表
yosys -p "read_verilog sta_async.v; synth -top sta_async; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; clean; write_verilog sta_async_net.v"

# 两种写法各跑一遍
sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run_false_path.tcl
sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run_clock_groups.tcl
```

## 关键结果

两种写法都把跨域路径移出检查集合，报告里只剩域内路径，最差 slack 同为 6.62 MET——就「检查哪些路径」而言两写法效果一致（差别在语义与可维护性，教程正文展开）。
