# ts-cocotb-toplevel-lang-error

**对应教程**：https://geek-doc.cn/eda/ts-cocotb-toplevel-lang-error.html

复现 cocotb Makefile 中 `TOPLEVEL_LANG` / `TOPLEVEL` / `SIM` 三类配置错配的真实报错，并给出修复与复跑确认。

## 环境

- Docker 镜像 `geek-eda:0.3-sta`（Ubuntu 24.04.5）
- cocotb 2.1.0（venv `/opt/venvs/cocotb`）、Icarus Verilog 12.0、Verilator 5.020

## 运行

```bash
bash run.sh
```

脚本在容器内顺序执行 `cases/` 下六组 Makefile 与两组纯 Verilator 编译，合并 stdout/stderr：

| 用例 | 改动 | 预期 |
|---|---|---|
| `good` | 配置正确 | `PASS=1`，退出码 0 |
| `nolang` | 省略 `TOPLEVEL_LANG` | 按 `VERILOG_SOURCES` 自动推断，仍通过 |
| `badlang` | `TOPLEVEL_LANG=vhdl` + Icarus | 打印 `Skipping simulation`，零测试执行，退出码 0 |
| `badspell` | `TOPLEVEL_LANG=Verilog`（大小写错误） | 同上 |
| `badtoplevel` | `TOPLEVEL=counter_top` 与模块名不符 | Icarus 报 `Unable to find the root module`，退出码 2 |
| `verilator` | `make SIM=verilator` | cocotb 报要求 Verilator >= 5.036，退出码 2 |
| `--no-timing` | 过程延迟 `#2` 用 `--no-timing` 编译 | `STMTDLY` 警告并退出码 1 |
| 默认 timing | 同一文件默认参数编译 | 通过（5.020 默认启用 timing） |

全部预期满足时末行打印 `ALL_ASSERTIONS=PASS`。
