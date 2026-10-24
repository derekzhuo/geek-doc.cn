# exp-cocotb-minimal-testbench

> **对应教程**：https://geek-doc.cn/eda-lab/sim/exp-cocotb-minimal-testbench.html（文档上线后生效）

最小 cocotb 测试平台：对一个计数器写 20 行 Python 测试，不碰 Verilog testbench，跑通 cocotb + Icarus 的最小闭环。

## 环境

- cocotb + Icarus Verilog（eda-golden-v1 镜像内 /opt/eda-venv 虚拟环境）
- Linux 下 pip install cocotb 并安装 iverilog 即可复现

## 复现

`bash run.sh`（等价于在本目录 make）
