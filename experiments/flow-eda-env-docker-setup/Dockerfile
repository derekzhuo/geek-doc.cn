FROM debian:bookworm-slim

# 只装最小工具集做环境验证；需要更多工具时在同一行追加 verilator yosys
RUN apt-get update \
 && apt-get install -y --no-install-recommends iverilog make ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
