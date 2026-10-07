# eda-lab-cocotb-first-tb

cocotb 2.1.0 入门实验：Python testbench 驱动 4 位计数器（带溢出标志），
随机使能激励 + 逐拍断言，多 seed 回归，另附一次故意注错（off-by-one）的 FAIL 演示。

配套文档：geek-doc.cn「cocotb 入门：用 Python 写 testbench 驱动计数器」（eda-lab/sim/el-cocotb-first-tb）。

## 运行

```bash
# 推荐：Docker（geek-eda:0.1.1 = 0.1 + libpython3.12，cocotb 运行必需）
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v <仓库根>/experiments:/work \
  -w /work/eda-lab-cocotb-first-tb geek-eda:0.1.1 make run
```

## 产物（out/）

- `regression.md`：5 个 seed 的回归汇总表（tests/failures/result）
- `seed<N>.log`：每个 seed 的完整 cocotb 日志
- `results_seed<N>.xml`：JUnit XML 结果
- `sim.log`：seed 1 日志的副本
- `fail.log` / `results_fail.xml`：INJECT_BUG=1 注错演示（off-by-one，必然 FAIL）

## 环境

cocotb 2.1.0 + Icarus Verilog 12.0 + Python 3.12（geek-eda:0.1.1 容器实测）。
注意 cocotb 2.x API 与 1.x 有差异：1-bit 信号 `.value` 返回 `Logic`（用 `int()` 取值，
没有 `.to_unsigned()`）；`Timer(10, "ns")` 的 `units=` 关键字已移除。
