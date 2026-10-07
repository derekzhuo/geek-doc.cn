# eda-lab-yosys-show

Yosys 网表图与 stat 报表的端到端实验样例（geek-doc.cn eda-lab 文档池 M0 样例，对应选题 `el-yosys-show-netlist`）。

## 运行（推荐：Docker 容器，零本地依赖）

```bash
docker run --rm -v <本仓库>/experiments:/work -w /work/eda-lab-yosys-show geek-eda:0.1 make run
```

镜像 `geek-eda:0.1` 含 iverilog / yosys / verilator / cocotb / graphviz，Dockerfile 见 geek-doc.cn 文档站仓库 `.codebuddy/skills/eda-toolchain/scripts/docker/`。

本机已装 yosys + graphviz 时也可直接 `make run`。

## 产物（out/）

- `netlist_rtl.svg` — `proc` 后 RTL 级网表图（寄存器/加法器形态）
- `netlist_gate.svg` — `synth` 后门级网表图（标准单元形态）
- `stat.txt` — 综合统计（单元/线网/触发器数量）
- `show_rtl.log` / `show_gate.log` / `stat.log` — 完整工具日志

实测环境：容器内 Yosys 0.33（ubuntu 24.04 apt）。
