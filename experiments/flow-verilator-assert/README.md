# Verilator 断言开启流程最小实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-assert.html

用一个深度 4、位宽 8 的同步 FIFO 走通 Verilator 5.020 的断言流程：RTL 里写 immediate `assert` 拦截「满时只写不读」的溢出操作，同一份违规 harness 分别在不开 `--assert`（违规被静默放过）与开启 `--assert`（仿真在违规当拍中止，退出码 134）下运行；修复 harness 尊重 `full` 反压后断言全开复跑干净。附录文件演示 `assert property` 中 `##` 周期延迟序列在 5.020 编译期被 `%Error-UNSUPPORTED` 拒绝的子集边界。

## 文件

| 文件 | 说明 |
|------|------|
| `fifo.sv` | DUT：4 项同步 FIFO，含 `a_no_overflow` / `a_no_underflow` 两条 immediate assert |
| `tb_bad.cpp` | 违规 harness：无视 `full` 连续写 5 拍 |
| `tb_fixed.cpp` | 修复后 harness：写满 -> 读空校验 -> 回绕再写读，自校验打印 `RESULT: PASS` |
| `sva_subset_delay.sv` | 故意触发编译期 `UNSUPPORTED` 的 `##` 延迟序列样例 |
| `run-native.sh` | 容器或本机执行的四步命令 |
| `run.sh` | 一键起 `geek-eda:0.3-sta` 容器复现 |
| `Makefile` | `make run` / `make clean` |

## 复现

需要 Docker 与镜像 `geek-eda:0.3-sta`（Verilator 5.020、g++、make）：

```bash
make run        # 等价于 ./run.sh
make clean      # 删除 build_* 构建目录
```

本机已装 Verilator 5.x 时可直接 `make NATIVE=1 run`。

预期：step1 退出码 0（断言未生效，仅作对照）、step2 退出码 134（断言中止仿真）、step3 打印 `RESULT: PASS`、step4 打印两条 `%Error-UNSUPPORTED` 并注明这是预期的子集边界。
