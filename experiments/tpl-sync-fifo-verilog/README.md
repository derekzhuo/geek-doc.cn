# tpl-sync-fifo-verilog：同步 FIFO 两种实现（计数器法 / 指针法）与自校验测试平台

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-sync-fifo-verilog.html

- `sync_fifo_count.v` — 计数器法：空满由占用计数器直接给出，DEPTH 可为任意正整数。
- `sync_fifo_ptr.v` — 指针法：指针多 1 bit 折返位区分满空，深度 = 2**AW。
- `tb_sync_fifo.v` — 双 DUT 同激励测试平台：写满判满 → 读空判空 → 满时并发读写保持满 → 2000 拍随机压力记分板对拍。

两个实现都支持「满时同拍读写」：读腾出的格子当拍即可被写入，FIFO 保持满。

## 复现

```bash
# 静态检查（需要 Verilator，或 docker 镜像 geek-eda:0.2）
verilator --lint-only -Wall sync_fifo_count.v
verilator --lint-only -Wall sync_fifo_ptr.v

# 仿真（Icarus Verilog 13.0）
iverilog -g2012 -o tb_sync_fifo.vvp tb_sync_fifo.v sync_fifo_count.v sync_fifo_ptr.v
vvp tb_sync_fifo.vvp
# 期望输出结尾：TEST PASSED: 0 errors, 1344 transfers
```
