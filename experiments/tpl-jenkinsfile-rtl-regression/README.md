# RTL 回归 Jenkinsfile 模板（tpl-jenkinsfile-rtl-regression）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-jenkinsfile-rtl-regression.html

夜间 RTL 回归的最小 CI 工程件：声明式 `Jenkinsfile`（cron 定时、双仿真器并行、JUnit 归档、失败才留日志/波形、失败邮件通知）+ 一个纯 bash 的回归 runner（逐用例执行、独立日志、PASS/FAIL 汇总、产出 JUnit XML、退出码透传），配两个 mock 用例可在没有任何 EDA 工具的机器上干跑。

## 目录结构

| 文件 | 作用 |
|------|------|
| `Jenkinsfile` | 声明式 pipeline 模板：夜间定时触发、TESTFILTER/SEED 参数、iverilog/verilator 并行轴、归档与失败通知 |
| `run-regression.sh` | 回归 runner：跑 `tests/<name>/run.sh`，产 `logs/*.log` 与 `results/regression.xml`，有失败 exit 1 |
| `tests/tc_pass/run.sh` | mock 用例：打印 TEST PASS，退出 0 |
| `tests/tc_fail/run.sh` | mock 用例：打印 TEST FAIL，退出 1 |
| `run-evidence.sh` | 证据采集：`bash -n` 校验、Jenkinsfile 结构核对清单、两轮 mock 回归 |

## 复现

```bash
chmod +x run-regression.sh tests/*/run.sh
./run-regression.sh              # 全量：1 PASS + 1 FAIL，退出码 1
TESTFILTER=tc_pass SEED=314 ./run-regression.sh   # 过滤：1 PASS，退出码 0
bash -n run-regression.sh        # 语法校验
bash run-evidence.sh             # 自动完成上述全部检查
```

Jenkinsfile 使用前需在 Jenkins 侧准备：两个 agent 标签 `sim-iverilog` / `sim-verilator`、凭据 `rtl-regression-notify-mail`（以及可选的 `notify-webhook`），并把 mock 的 `tests/` 换成真实 testbench、`make compile SIM=...` 换成工程实际编译命令。
