# tpl-dockerfile-eda-env：开源 EDA 一体化 Dockerfile 模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-dockerfile-eda-env.html

一个 Dockerfile 装齐 `iverilog`、`verilator`、`yosys` 三件套，配一份容器内冒烟脚本，验证三件套各自能跑通最小 RTL。

## 目录结构

```text
.
├── Dockerfile        # debian:bookworm-slim 基底，apt 一层装齐三件套
└── src
    ├── hello.v       # 带复位的 4 位计数器（三工具共用的最小 RTL）
    ├── tb_hello.v    # iverilog 自检 testbench
    └── smoke.sh      # iverilog 仿真 + verilator lint + yosys 综合冒烟
```

## 复现方式

```bash
# 1. 构建镜像（约 3–8 分钟，取决于 apt 源速度）
docker build -t geek-eda-mini:local .

# 2. 容器内跑三件套冒烟
docker run --rm -v "$PWD/src":/work -w /work geek-eda-mini:local bash smoke.sh

# 3. 只看三工具版本
docker run --rm geek-eda-mini:local
```

冒烟通过的标志是最后一行打印 `SMOKE PASS`。
