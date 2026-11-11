# flow-cocotb-random-seed

**对应教程**：https://geek-doc.cn/eda/flow-cocotb-random-seed.html

cocotb 2.1 随机种子回归流程的配套实验：一个 8 位饱和加法器 DUT，一个用 Python 随机激励自校验的 cocotb 测试，外加一个 shell 种子循环回归脚本。

## 文件

| 文件 | 说明 |
|---|---|
| `sat_add8.v` | 正确的 DUT：`sum = min(a+b, 255)`，`sat` 标志钳位 |
| `sat_add8_buggy.v` | 边界 bug 版本：判空写成 `total > 256`，`a+b == 256` 时回绕成 0 |
| `test_sat_add.py` | cocotb 2.1 测试，300 笔随机事务，参考模型用 Python 计算期望值 |
| `Makefile` | cocotb Makefile（SIM=icarus），`DUT_FILE` 可切换 buggy 版本 |
| `run_seeds.sh` | 种子循环回归脚本：逐种子独立日志、PASS/FAIL 判定、失败汇总 |

## 复现

需要 Docker 镜像 `geek-eda:0.3-sta`（cocotb 2.1.0 + Icarus Verilog 12.0）。

```bash
# 三个种子扫 buggy 版本（seed 2 必挂，seed 1/7 漏检），退出码 1
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && SEEDS="1 2 7" DUT_FILE=sat_add8_buggy.v bash run_seeds.sh'

# 同一种子复现失败现场
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && make sim DUT_FILE=sat_add8_buggy.v COCOTB_RANDOM_SEED=2'

# 修复后三个种子全过，退出码 0
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && SEEDS="1 2 7" bash run_seeds.sh'
```

`sim_build/`、`results.xml`、`logs/` 为运行产物，不入库。
