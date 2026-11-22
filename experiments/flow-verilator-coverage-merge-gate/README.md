# Verilator 多轮覆盖率合并与 CI 阈值门禁实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-coverage-merge-gate.html

同一个 8 位可加载计数器 `rtl/counter.v`（带 `en`/`load`/`clear` 与计满回绕），用一个可参数化种子的 C++ harness 跑三种激励，演示 Verilator 5.020 下多份 `coverage.dat` 的合并与覆盖率阈值门禁：

- `sim/tb.cpp`：`./Vcounter <seed>`，种子 1/2/3 激励范围不同，各写 `coverage_seedN.dat`；三个种子都不驱动 `clear`，保留一个合并后仍存在的真实缺口
- `scripts/coverage_summary.sh`：从 `.dat` 文件按 `v_line`/`v_branch`/`v_toggle` 分类统计命中数与百分比
- `scripts/coverage_gate.py`：解析行覆盖率并与阈值比较，达标退出 0、不达标退出 1，可直接接进 CI
- `run.sh`：编译一次、三个种子各跑一遍、`verilator_coverage --write` 合并、出报告，再用同一 `merged.dat` 演示宽松阈值通过（70%，rc=0）与收紧阈值失败（90%，rc=1）

## 复现

需要本机有 Docker 与 `geek-eda:0.4-flow` 镜像（Verilator 5.020 + verilator_coverage）：

```bash
make run        # 等价于 docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow bash run.sh
```

实测结果（2026-11-23，完整记录见 `results/run.log`）：

| 数据来源 | v_line | v_toggle | v_branch |
|---|---|---|---|
| seed 1（仅计数 10 拍） | 2/4（50.0%） | 7/21（33.3%） | 2/2（100%） |
| seed 2（计数 + 加载 0x5A） | 3/4（75.0%） | 14/21（66.7%） | 2/2（100%） |
| seed 3（加载 0xF0 + 回绕 + 加载 0x0F） | 3/4（75.0%） | 20/21（95.2%） | 2/2（100%） |
| 三份合并 merged.dat | 3/4（75.0%） | 20/21（95.2%） | 2/2（100%） |

合并后唯一的行覆盖缺口是 `clear` 分支（激励从未驱动该端口），所以 70% 阈值 PASS、90% 阈值 FAIL。

## 关于 genhtml/lcov

`geek-eda:0.4-flow` 镜像内没有 `genhtml`/`lcov`，实验用 `verilator_coverage -write-info report.info` 导出 lcov 格式信息文件；在装有 lcov 的环境对该文件执行 `genhtml report.info -o html` 即可生成网页报告。

## 产物（均不入库）

- `obj_dir/`：插桩编译产物与 `Vcounter` 可执行文件
- `coverage_seed*.dat` / `merged.dat`：各种子与合并后的覆盖率数据
- `report.info`：lcov 格式导出
- `logs_merged/`：`--annotate` 生成的逐行命中注释源码，`%000000` 表示零命中

清理：`make clean`
