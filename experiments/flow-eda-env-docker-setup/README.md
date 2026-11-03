# 开源 EDA 环境搭建（Docker 镜像一行起）

**对应教程**：https://geek-doc.cn/chip-design/beginner/flow-eda-env-docker-setup.html

用 Docker 搭一个版本固定的开源 EDA 工具链环境：镜像负责工具（iverilog / Verilator / Yosys / OpenSTA），挂载目录负责工程，`docker run --rm` 跑完容器即删，产物经挂载点写回宿主机。

## 目录内容

- `Dockerfile`：基于 `debian:bookworm-slim` 的最小镜像，只装 iverilog 与 make，供读者从零构建；
- `run.sh`：从零构建 `flow-eda-mini:0.1`，在容器内打印版本并挂载 `demo/` 跑通编译仿真；
- `class-run.sh`：用本机已有的版本固定镜像 `geek-eda:0.3-sta`（iverilog 12.0 / Verilator 5.020 / Yosys 0.33 / OpenSTA 2.0.17）核对 image id 与四工具版本，并挂载 `demo/` 跑同一实验；
- `demo/`：两位加法器 `design.v` 与 testbench `tb_add2.v`，期望输出 `sum=3 (expect 3)`。

## 复现方式

```bash
# 路线一：自行构建最小镜像（bookworm 仓库 iverilog 11.0）
bash run.sh

# 路线二：已有 geek-eda:0.3-sta 镜像时（iverilog 12.0）
bash class-run.sh
```

前置条件：macOS/Linux 已安装并启动 Docker（实测 Docker 24.0.7）。产物 `demo/sim.vvp` 为编译生成文件，不纳入版本管理。
