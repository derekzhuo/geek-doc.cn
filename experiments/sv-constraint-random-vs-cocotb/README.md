# sv-constraint-random-vs-cocotb

**对应教程**：https://geek-doc.cn/chip-design/verification/sv-constraint-random-vs-cocotb.html（上线后生效）

同一随机激励需求的两条实现路径对照实验的 cocotb 侧：用 Python `random` 给一个 8 位宽、16 深度的异步 FIFO 打 200 笔随机背靠背读写（写概率 0.8 / 读概率 0.7，固定种子 20261020），在 Icarus Verilog 上回归，验证跨时钟域数据完整性。

## 复现

需要 iverilog 与 Python 环境装好 cocotb（本实验用 cocotb 1.8.1 + Icarus Verilog 11.0）：

```sh
make run    # 内部调 cocotb 的 Makefile.sim，SIM=icarus WAVES=1
```

Makefile 默认假设 cocotb 装在 `/opt/eda-venv`，本地安装时把 `COCOTB_VENV` 改成你的 venv 路径，或直接按教程正文给出的完整 `make -f .../Makefile.sim` 命令展开执行。

## 目录

- `rtl/async_fifo.v` — 被测异步 FIFO（格雷码指针 + 两级同步）
- `testbench/test_async_fifo.py` — cocotb 测试：`single_write_read` 冒烟 + `random_back_to_back` 随机回归
- `Makefile` — cocotb/Icarus 回归入口

预期结果：`TESTS=2 PASS=2 FAIL=0 SKIP=0`，随机用例打印 `200 tokens delivered in order across async clocks OK`。
