# eda-errlog batch1：开源 EDA 工具真实报错复现实验

8 个最小复现工程，对应 geek-doc.cn 已发布的 8 篇报错速查文档。每个目录含报错源码、
一键复现脚本 `run.sh` 与说明；原始证据日志（2026-10-21 凌晨在 eda-golden v1 镜像
实例真机采集）见 geek-doc.cn 站点各文档引用的 `/shots/<slug>/*.log`，可下载核对。

| 目录 | 工具 | 对应文档（geek-doc.cn） |
|---|---|---|
| `ts-yosys-error-no-top-module` | Yosys 0.9 | [Yosys 找不到顶层模块速查](https://geek-doc.cn/eda/ts-yosys-error-no-top-module.html) |
| `ts-yosys-error-module-not-declared-synth` | Yosys 0.9 | [Yosys 模块未声明（综合阶段）速查](https://geek-doc.cn/eda/ts-yosys-error-module-not-declared-synth.html) |
| `ts-yosys-warning-width-mismatch-assign` | Yosys 0.9 + iverilog | [Yosys 位宽不匹配告警速查](https://geek-doc.cn/eda/ts-yosys-warning-width-mismatch-assign.html) |
| `ts-yosys-abc-fail-missing-cell-library` | Yosys 0.9 + sky130A | [Yosys abc 缺单元库失败速查](https://geek-doc.cn/eda/ts-yosys-abc-fail-missing-cell-library.html) |
| `ts-verilator-width-mismatch-WIDTH` | Verilator 4.038 | [Verilator WIDTH 位宽告警速查](https://geek-doc.cn/eda/ts-verilator-width-mismatch-WIDTH.html) |
| `ts-verilator-caseincomplete-default` | Verilator 4.038 | [Verilator CASEINCOMPLETE 告警速查](https://geek-doc.cn/eda/ts-verilator-caseincomplete-default.html) |
| `ts-verilator-cannot-find-module-file` | Verilator 4.038 | [Verilator 找不到模块文件速查](https://geek-doc.cn/eda/ts-verilator-cannot-find-module-file.html) |
| `ts-cocotb-NO_TEST_ERROR` | cocotb 1.8.1 + Icarus 11 | [cocotb NO_TEST_ERROR 速查](https://geek-doc.cn/eda/ts-cocotb-NO_TEST_ERROR.html) |

## 运行环境

- Ubuntu 22.04（原始证据环境）：`apt install yosys verilator iverilog`，cocotb 实验另需
  Python 3.10+ 虚拟环境 `pip install cocotb`。
- macOS 亦可跑（brew 装同名工具）；Verilog 源码与工具大版本无关，报错文案以小版本为准会略有差异。
- abc liberty 实验需要 sky130A PDK（volare/open_pdks 安装），无 PDK 时 `run.sh` 自动只复现报错、跳过修复项。

## 来源说明

7 个 HDL 实验源码原样重建自内容仓采集脚本 `collect-evidence.sh` 的 heredoc（零信息损失）；
cocotb 实验的原始 lab 位于 eda-golden 镜像内、未入库，本目录的 `ts-cocotb-NO_TEST_ERROR/lab/`
是按原始日志（TOPLEVEL/MODULE/两个测试名与断言信息）重建的等价最小工程，2026-10-22 在
macOS + Icarus 13 + cocotb 1.9 本地复跑通过，见该目录 README。
