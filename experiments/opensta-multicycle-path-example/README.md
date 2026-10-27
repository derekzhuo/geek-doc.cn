# OpenSTA 多周期路径 set_multicycle_path 对照实验（opensta-multicycle-path-example）

**对应教程**：https://geek-doc.cn/chip-design/intermediate/opensta-multicycle-path-example.html（上线后生效）

同一网表跑两遍：默认单拍 setup 检查 vs 加 `set_multicycle_path 2 -setup`（hold 回到 1），看 data required time 从 10.00 变 20.00、slack 从 8.76 变 18.76。

## 文件

- `sta_demo.v` —— 被测 RTL（与 create_clock 实验同一设计）
- `run_nomcp.tcl` —— 无例外，单拍检查
- `run_mcp.tcl` —— 加多周期例外
- `output/nomcp.log` / `output/mcp.log` —— 两遍报告

## 实验环境

- Ubuntu 22.04 + Yosys 0.9 + OpenSTA 2.4.0（OpenLane docker 镜像内 `/build/bin/sta`），sky130_fd_sc_hd tt_025C_1v80

## 复现

```bash
# 先综合网表（同 create_clock 实验①）
yosys -p "read_verilog sta_demo.v; synth -top sta_demo; \
  dfflibmap -liberty $LIB; abc -liberty $LIB; clean; write_verilog sta_demo_net.v"

# 两遍 STA 对照
sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run_nomcp.tcl
sudo docker run --rm -v $PWD:/w -w /w -e STA_LIB=$LIB \
  efabless/openlane:d054702b2cce04761cc2bc598f6b95c9d8ca7c6c-amd64 /build/bin/sta -exit run_mcp.tcl
```

例外写法（setup 给 2 拍、hold 必须配套回到 1）：

```tcl
set_multicycle_path 2 -setup -from [all_registers] -to [all_registers]
set_multicycle_path 1 -hold  -from [all_registers] -to [all_registers]
```

## 关键结果

无例外时 setup 单拍检查、slack 8.76 MET；加例外后同一最差路径 slack 18.76 MET，data required time 从 10.00 放宽到 20.00。
