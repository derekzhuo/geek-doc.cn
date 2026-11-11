# flow-yosys-synth-ice40：iCE40 RTL 到比特流最小链路

**对应教程**：https://geek-doc.cn/eda/flow-yosys-synth-ice40.html

一个 24 位计数器（高 4 位驱动 LED）走完 Lattice iCE40 开源后端三件套：

1. `yosys -s synth.ys`：`read_verilog` + `synth_ice40 -json top.json`，RTL 映射为
   `SB_LUT4` / `SB_DFFR` / `SB_CARRY` 原语并写出 JSON 网表；
2. `nextpnr-ice40 --hx1k --package tq144 --json top.json --pcf top.pcf --asc top.asc`：
   按 PCF 引脚约束布局布线，产出 ASCII 比特流 `.asc`；
3. `icepack top.asc top.bin`：打包成可烧录的二进制比特流。

## 复现

需要 Docker 镜像 `geek-eda:0.4-flow`（Yosys 0.33 + nextpnr-ice40 0.6 + Project IceStorm）：

```bash
make            # 等价于依次执行 yosys / nextpnr-ice40 / icepack
# 或
bash ./run.sh
```

本机原生安装工具链时：`make DOCKER_RUN=""`。

目标器件为 iCEstick 评估板（iCE40-HX1K-TQ144），引脚见 `top.pcf`
（clk=21、rst_n=8、led=99/98/97/96）。换器件改 Makefile 的 `DEVICE` / `PACKAGE`
与 PCF 即可，例如 `--up5k --package sg48`。

产物 `top.json` / `top.asc` / `top.bin` 为生成文件，不入库。
