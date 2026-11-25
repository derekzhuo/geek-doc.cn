# flow-ngspice-monte-carlo-corner

**对应教程**：https://geek-doc.cn/eda/flow-ngspice-monte-carlo-corner.html（上线后生效）

用 ngspice-42 对一个 1.8 V、两只 10 kΩ 电阻组成的分压器做重复直流工作点分析。实验包含 50 次固定种子的独立随机抽样，以及标称、R1 偏高且 R2 偏低、R1 偏低且 R2 偏高三个确定性设置。

## 实验边界

- 两只电阻各自在标称值的 ±5% 内均匀抽样，随机序列由 Python `random.Random(20261126)` 生成，不依赖仿真器版本的随机函数。
- 这里变化的是教学夹具的电阻值，不是代工厂工艺模型；50 次运行用于展示自动化与统计流程，不能据此估计量产良率。
- `sample_stddev_v` 使用样本标准差，分母为 `n-1`。

## 文件

- `divider.cir.tmpl`：分压器网表模板，输出 `v(out)`。
- `scripts/run_analysis.py`：生成 53 份网表，逐个调用 ngspice，保存逐次结果并汇总统计。
- `scripts/validate_results.py`：重新生成随机序列，独立重算统计值并检查 53 次运行的退出码。
- `run.sh`：完整运行入口。

## 复现

```bash
make run
# 等价于
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

运行后，`results/raw_results.csv` 保存 50 次随机抽样与 3 个确定性设置，`results/summary.json` 保存统计摘要，`results/ngspice/` 保存每次仿真的完整输出，`results/decks/` 保存实际提交给 ngspice 的网表。校验成功时末行包含 `VALIDATION count=50 random_sequence=match summary=match`。
