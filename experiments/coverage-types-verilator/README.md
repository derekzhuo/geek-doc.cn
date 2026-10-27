# Verilator 覆盖率：行覆盖与翻转覆盖（coverage-types-verilator）

**对应教程**：https://geek-doc.cn/chip-design/verification/coverage-types-verilator.html（上线后生效）

用 `verilator --coverage` 跑一个 8-bit 计数器（加/减/load/环绕），产出行覆盖（lcov 格式）与翻转覆盖两类数据库，并演示翻转覆盖如何揭示高位惰性（count[7] 仅翻转 2 次）。

## 文件

- `counter.v` —— 8-bit 计数器 DUT
- `sim_main.cpp` —— Verilator C++ 驱动：跑激励序列后写 coverage.dat
- `output/coverage.log` —— 仿真日志 + 覆盖率汇总
- `output/coverage.info` —— lcov 行覆盖报告

## 实验环境

- Ubuntu 22.04 + Verilator 4.038

## 复现

```bash
verilator --cc --exe --coverage -Wno-fatal counter.v sim_main.cpp -o counter_sim
make -C obj_dir -f Vcounter.mk counter_sim     # 4.038 无 --build，拆成两步
./obj_dir/counter_sim                          # 运行并写 coverage.dat
verilator_coverage coverage.dat                # 打印覆盖率汇总
verilator_coverage --write-info coverage.info coverage.dat   # 导出 lcov
```

## 关键结果

仿真完成（`count after load = 0x42 / final count = 0x47 / SIM_DONE`），行覆盖接近全绿；翻转覆盖显示 `count[7]` 整个仿真只翻转 2 次——激励没压到高位翻转，正是翻转覆盖比行覆盖更能暴露验证盲区的实例。
