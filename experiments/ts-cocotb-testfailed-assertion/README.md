# ts-cocotb-testfailed-assertion

**对应教程**：https://geek-doc.cn/eda/ts-cocotb-testfailed-assertion.html（上线后生效）

cocotb 断言失败（AssertionError / TestFailed）读法演示：一个 4 bit 计数器 DUT + 一个故意写错期望值的 testbench，用固定 RANDOM_SEED=1234 跑两次，验证「同 seed 输出完全一致」。

## 复现

```bash
# 需要：cocotb 2.x + Icarus Verilog
make RANDOM_SEED=1234   # 第一次：断言失败，FAIL=1
make RANDOM_SEED=1234   # 第二次：输出与第一次逐行一致（除速率统计）
```

`run1.log` / `run2.log` 是两次实跑的完整输出。
