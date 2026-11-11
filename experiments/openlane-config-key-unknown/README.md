# openlane-config-key-unknown

**对应教程**：https://geek-doc.cn/eda/ts-openlane-config-key-unknown.html

OpenLane 2023.07.19（sky130A，docker 镜像 efabless/openlane:d054702）复现「config.json 键名拼错」。

## 复现

```bash
# 错误：VERILOG_FILES 拼成 VERILOG_FIELS（见 configs/config.bad.json）
./run.sh
```

`run.sh` 先跑错误配置（step 0 verilator_lint_check 报
`no such variable (read trace on "::env(VERILOG_FILES)")`），
再把键名改回 `VERILOG_FILES` 跑到 synthesis 通过。

## 目录

- `src/small_counter.v`：最小 12 位计数器设计。
- `configs/config.bad.json` / `config.good.json`：错误 / 正确配置。
- `run.sh`：两次对照运行（需要 OpenLane docker 环境与上层 olrun.sh 包装脚本）。
