# eda-lab-verilator-lint

Verilator `--lint-only` 静态检查实操：一份故意埋了 6 类典型问题的 RTL，收集真实告警原文，并演示两种 waiver（豁免）方式。

配套文档：geek-doc.cn `eda-lab/sim/` 的《verilator lint》篇。

## 运行（Docker，geek-eda:0.1 / Verilator 5.020）

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-verilator-lint geek-eda:0.1 make run
```

## 文件

| 文件 | 作用 |
|---|---|
| `lint_demo.v` | 问题 RTL：WIDTHTRUNC / WIDTHEXPAND / UNOPTFLAT / LATCH / UNUSEDSIGNAL / CASEINCOMPLETE 六类问题 |
| `lint_demo_waived.v` | 同上一份，但用 `/* verilator lint_off XXX */` 注释豁免 WIDTHTRUNC 与 UNOPTFLAT，并显式修复 WIDTHEXPAND |
| `lint_off/waivers.vlt` | waiver 方式二：.vlt 配置文件，集中豁免 CASEINCOMPLETE / UNUSEDSIGNAL（含未驱动） |
| `Makefile` | 四条命令：默认告警集 / `-Wall` 全开 / 注释 waiver / .vlt waiver |
| `out/*.log` | 真实运行输出（退出码都记录在日志尾部） |

## 实测结论（Verilator 5.020）

- 默认告警集：6 条告警（WIDTH×3、UNOPTFLAT、LATCH、CASEINCOMPLETE），UNUSEDSIGNAL 不默认开启。
- `-Wall`：11 条告警，多出来的 5 条全是 UNUSEDSIGNAL。
- 有告警即 `%Error: Exiting due to N warning(s)`，退出码 1 —— CI 里可直接当门禁。
- 注释 waiver 后 11 → 7 条；.vlt waiver 后 11 → 4 条。
