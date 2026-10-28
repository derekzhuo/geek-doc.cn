# 异步 FIFO 可复用 Verilog 模板（格雷码指针 + 两级同步器）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-async-fifo-verilog.html（上线后生效）

参数化（位宽 / 深度，深度必须为 2 的幂）的异步 FIFO：格雷码指针跨时钟同步、两级同步器、满/空标志格雷码比较法（寄存量输出，Cummings 风格）。

## 文件

- `async_fifo.v` — 模板本体，参数 `WIDTH` / `DEPTH`
- `tb_async_fifo.v` — 测试平台：写满判满 → 读空判空 → 双时钟并发随机读写 + 记分板数据一致性校验

## 复现

```bash
# 静态检查（Verilator 5.020，本实验在 geek-eda:0.2 docker 镜像中运行）
verilator --lint-only -Wall async_fifo.v

# 仿真（Icarus Verilog 13.0）
iverilog -g2012 -o tb_async_fifo.vvp tb_async_fifo.v async_fifo.v
vvp tb_async_fifo.vvp
# 期望输出结尾：== TEST PASSED: 0 errors ==
```

测试平台里写时钟 100 MHz、读时钟约 71.4 MHz，读写使能各按 2/3 概率随机，验证跨时钟并发下的数据完整性。
