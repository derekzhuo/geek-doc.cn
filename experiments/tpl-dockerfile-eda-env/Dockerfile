# 团队标准 EDA 镜像上加项目层的 Dockerfile 模板（本机实证版）
# 基底 geek-eda:0.1 已内置 iverilog 12.0 / verilator 5.020 / yosys 0.33（Ubuntu 24.04）
# 构建：docker build -t geek-eda-mini:local .
# 冒烟：docker run --rm -v "$PWD/src":/work -w /work geek-eda-mini:local bash smoke.sh
#
# 从公共 debian 基底从零装三件套的等价写法见同目录 Dockerfile.public
# （需要外网访问 apt 源与 Docker Hub，内网/受限网络以本文件为准）。
FROM geek-eda:0.1

WORKDIR /work

# 把工程脚本与 RTL 烤进镜像层；日常调试也可用 -v 挂载覆盖 /work
COPY src/ /work/

# 建镜像后默认做一次三件套版本核对，镜像可直接当版本探针用
CMD ["bash", "-lc", "iverilog -V | head -1; verilator --version; yosys -V"]
