# exp-waveform-png-gtkwave-surfer

> **对应教程**：https://geek-doc.cn/eda-lab/wave/exp-waveform-png-gtkwave-surfer.html（文档上线后生效）

无头环境波形出图实验：iverilog 产出 VCD 后，优先用 gtkwave 无头模式转 PNG，无 X11 环境自动兜底为 vcd2wavedrom.py 生成 WaveJSON（供 wavedrom-cli 渲染）。

## 环境

- iverilog + python3（eda-golden-v1 镜像 /opt/eda-venv）
- gtkwave 存在时尝试无头转 PNG，否则走 wavedrom JSON 兜底

## 复现

`bash run.sh`（产出 VCD，再转 PNG 或 WaveJSON）
