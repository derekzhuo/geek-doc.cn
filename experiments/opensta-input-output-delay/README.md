# OpenSTA set_input_delay / set_output_delay 对照实验（opensta-input-output-delay）

**对应教程**：https://geek-doc.cn/chip-design/intermediate/opensta-input-output-delay.html（上线后生效）

同一网表、同一 10ns 时钟跑两遍：一遍无 IO 约束，一遍加 `set_input_delay 2.0` + `set_output_delay 1.5`，对照最差路径与 slack 的变化——IO 延迟直接吃进建立时间预算。

## 文件

- `sta_demo.v` —— 被测 RTL（与 create_clock 实验同一设计）
- `run_nodelay.tcl` —— 只 create_clock
- `run_delay.tcl` —— create_clock + set_input_delay/set_output_delay
- `output/nodelay.log` / `output/delay.log` —— 两遍报告

## 实验环境

- Ubuntu 22.04 + Yosys 0.9 + OpenSTA 2.4.0（OpenLane docker 镜像内 `/build/bin/sta`），sky130_fd_sc_hd tt_025C_1v80

## 复现

```bash
# 先综合网表（同 create_clock 实验①）
yosys -p "read_verilog sta_demo.v; synth -top sta_demo; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; clean; write_verilog sta_demo_net.v"

# 两遍 STA 对照
sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run_nodelay.tcl
sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run_delay.tcl
```

## 关键结果

| 跑法 | Startpoint | slack |
|---|---|---|
| 无 IO 约束 | `_37_`（内部 FF） | 8.76 MET |
| 有 IO 约束 | `en`（input port clocked by clk） | 7.11 MET |

加了 IO 延迟后最差路径从 reg-to-reg 变为输入端口路径，slack 从 8.76 缩到 7.11。
