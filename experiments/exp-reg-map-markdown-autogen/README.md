# exp-reg-map-markdown-autogen

> **对应教程**：https://geek-doc.cn/chip-design/intermediate/exp-reg-map-markdown-autogen.html（文档上线后生效）

寄存器表单一数据源实验：寄存器映射只维护一份 Markdown 表，脚本自动生成 Verilog 头文件 regs.vh 与 C 头文件 regs.h，并用 iverilog 编译消费模块验证生成结果可用。

## 环境

- python3（eda-golden-v1 镜像内 /opt/eda-venv）+ iverilog
- Linux 下任意 python3 + iverilog 可复现

## 复现

`bash run.sh`（gen_regs.py 从 regs.md 生成 regs.vh/regs.h，再编译消费模块验证）
