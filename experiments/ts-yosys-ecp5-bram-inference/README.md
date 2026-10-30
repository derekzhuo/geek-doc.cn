# Yosys ECP5 BRAM 推断对照实验

**对应教程**：https://geek-doc.cn/eda/ts-yosys-ecp5-bram-inference.html

`async_ram.v` 使用组合读端口，`sync_ram.v` 将读数据寄存一个时钟周期。两份设计的容量均为 1024×16 位，用于观察 `synth_ecp5` 的存储器映射差异。

## 复现

安装 Docker 并准备 `geek-eda:0.2` 镜像，然后在本目录执行：

```bash
bash run.sh
```

脚本依次运行两个模块的 `read_verilog` 与 `synth_ecp5 -top`，并保留综合末尾的单元统计。运行不需要 `nextpnr-ecp5`，也不产生布局布线结果。
