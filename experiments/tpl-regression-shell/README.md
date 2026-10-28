# tpl-regression-shell：仿真回归控制 Shell 脚本模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-regression-shell.html

一个用纯 bash 写的仿真回归控制模板：种子清单/随机种子 → 每种子独立日志 → grep 判定 PASS/FAIL → 失败汇总与非零退出码。

## 文件

- `alu8.v`：演示用 DUT（8 位 ALU，加法/减法/与/或）
- `tb_alu8.v`：自校验 testbench，种子经 `+seed=N` 传入；定义 `FAIL_INJECT` 宏时 seed=13 必挂（演示失败路径）
- `run_regress.sh`：回归控制脚本本体

## 复现

需要 Icarus Verilog（13.0 实测）。在本目录执行：

```bash
chmod +x run_regress.sh
SEED_LIST="3 5 8 21 34" ./run_regress.sh          # 全部 PASS，退出码 0
INJECT_FAIL=1 SEED_LIST="3 5 13 21 34" ./run_regress.sh  # seed=13 FAIL，退出码 1
```

环境变量接口：`SEED_LIST`（指定种子）、`NSEED`（随机种子个数，默认 5）、`LOG_DIR`（日志目录，默认 `logs/`）、`INJECT_FAIL`（注入失败演示）。
