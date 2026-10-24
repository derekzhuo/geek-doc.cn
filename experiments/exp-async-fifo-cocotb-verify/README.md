# exp-async-fifo-cocotb-verify

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-async-fifo-cocotb-verify.html（文档上线后生效）

异步 FIFO 的 cocotb 验证：Python 测试平台跨读写两个时钟域校验 FIFO 数据完整性，覆盖满（写侧反压）与空（读侧停顿）边界，随机种子确定可复现。

## 环境

- cocotb + Icarus Verilog（eda-golden-v1 镜像内 /opt/eda-venv 虚拟环境）
- Linux 下 pip install cocotb 并安装 iverilog 即可复现

## 复现

`make run`（cocotb 回归，WAVES=1 输出 FST 波形）
