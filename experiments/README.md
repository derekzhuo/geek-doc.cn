# 实验索引

> 本文件由 `node scripts/gen-experiment-index.mjs` 生成，请勿手工编辑。当前共 **296 个实验目录**。

每个实验都有独立目录和 README。教程链接指向中文讲解；“实验材料”列出目录内可见的日志、数据、图或波形，具体复现方式以各实验 README 为准。

## 分类统计

| 分类 | 数量 |
|---|---:|
| 开源 EDA 入门 | 12 |
| 可运行模板 | 18 |
| 排错案例 | 89 |
| 数字设计实验 | 18 |
| 芯片参考与器件实验 | 15 |
| 性能剖析 | 3 |
| 验证方法学 | 4 |
| 综合实验 | 71 |
| EDA 流程实操 | 46 |
| OpenSTA / 时序分析 | 5 |
| Vivado / XSim / XDC | 15 |

## 全部实验

| 分类 | 实验 | 中文教程 | 实验材料 |
|---|---|---|---|
| 开源 EDA 入门 | [eda-lab-cocotb-first-tb](./eda-lab-cocotb-first-tb/) | [教程](https://geek-doc.cn/eda-lab/sim/el-cocotb-first-tb.html) | output/ |
| 开源 EDA 入门 | [eda-lab-iverilog-common-errors](./eda-lab-iverilog-common-errors/) | [教程](https://geek-doc.cn/eda-lab/sim/el-iverilog-common-errors.html) | output/ |
| 开源 EDA 入门 | [eda-lab-iverilog-first-sim](./eda-lab-iverilog-first-sim/) | [教程](https://geek-doc.cn/eda-lab/sim/el-iverilog-first-sim.html) | output/ |
| 开源 EDA 入门 | [eda-lab-iverilog-vcd-wave](./eda-lab-iverilog-vcd-wave/) | [教程](https://geek-doc.cn/eda-lab/wave/el-iverilog-vcd-wave.html) | 图/波形 + 日志/数据 |
| 开源 EDA 入门 | [eda-lab-verilator-binary-sim](./eda-lab-verilator-binary-sim/) | [教程](https://geek-doc.cn/eda-lab/sim/el-verilator-binary-sim.html) | output/ |
| 开源 EDA 入门 | [eda-lab-verilator-coverage](./eda-lab-verilator-coverage/) | [教程](https://geek-doc.cn/eda-lab/sim/el-verilator-coverage.html) | output/ |
| 开源 EDA 入门 | [eda-lab-verilator-lint](./eda-lab-verilator-lint/) | [教程](https://geek-doc.cn/eda-lab/sim/el-verilator-lint.html) | output/ |
| 开源 EDA 入门 | [eda-lab-wave-viewer-compare](./eda-lab-wave-viewer-compare/) | [教程](https://geek-doc.cn/eda-lab/wave/el-wave-viewer-compare.html) | 图/波形 + output/ + 日志/数据 |
| 开源 EDA 入门 | [eda-lab-yosys-common-errors](./eda-lab-yosys-common-errors/) | [教程](https://geek-doc.cn/eda-lab/synth/el-yosys-common-errors.html) | output/ |
| 开源 EDA 入门 | [eda-lab-yosys-show](./eda-lab-yosys-show/) | [教程](https://geek-doc.cn/eda-lab/synth/el-yosys-show-netlist.html) | output/ |
| 开源 EDA 入门 | [eda-lab-yosys-stat-report](./eda-lab-yosys-stat-report/) | [教程](https://geek-doc.cn/eda-lab/synth/el-yosys-stat-report.html) | output/ |
| 开源 EDA 入门 | [eda-lab-yosys-synth-steps](./eda-lab-yosys-synth-steps/) | [教程](https://geek-doc.cn/eda-lab/synth/el-yosys-synth-steps.html) | output/ |
| 可运行模板 | [异步 FIFO 可复用 Verilog 模板（格雷码指针 + 两级同步器）](./tpl-async-fifo-verilog/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-async-fifo-verilog.html) | 见 README |
| 可运行模板 | [tpl-axi-lite-register-sv：AXI4-Lite 从机寄存器接口模板](./tpl-axi-lite-register-sv/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-axi-lite-register-sv.html) | 见 README |
| 可运行模板 | [cocotb 最小测试平台 Python 模板实验](./tpl-cocotb-minimal-python/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-cocotb-minimal-python.html) | 见 README |
| 可运行模板 | [tpl-dockerfile-eda-env：开源 EDA 一体化 Dockerfile 模板](./tpl-dockerfile-eda-env/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-dockerfile-eda-env.html) | 见 README |
| 可运行模板 | [RTL 提交前 lint 钩子模板（pre-commit + Verilator）](./tpl-git-precommit-rtl-lint/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-git-precommit-rtl-lint.html) | 见 README |
| 可运行模板 | [IO 约束 XDC 模板 · OpenSTA 验证实验](./tpl-io-constraint-xdc/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-io-constraint-xdc.html) | 见 README |
| 可运行模板 | [RTL 回归 Jenkinsfile 模板（tpl-jenkinsfile-rtl-regression）](./tpl-jenkinsfile-rtl-regression/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-jenkinsfile-rtl-regression.html) | 见 README |
| 可运行模板 | [tpl-openlane-config-json](./tpl-openlane-config-json/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-openlane-config-json.html) | 日志/数据 |
| 可运行模板 | [仿真日志解析 Python 模板](./tpl-python-log-parser/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-python-log-parser.html) | 日志/数据 |
| 可运行模板 | [tpl-regression-shell：仿真回归控制 Shell 脚本模板](./tpl-regression-shell/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-regression-shell.html) | 见 README |
| 可运行模板 | [SystemVerilog 记分板模板](./tpl-scoreboard-sv/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-scoreboard-sv.html) | 见 README |
| 可运行模板 | [tpl-sim-makefile —— 仿真工程通用 Makefile 模板](./tpl-sim-makefile/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-sim-makefile.html) | 见 README |
| 可运行模板 | [STA 时序报告提取 TCL 脚本模板实验](./tpl-sta-report-extract-tcl/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-sta-report-extract-tcl.html) | 见 README |
| 可运行模板 | [SystemVerilog Assertion 高频模板实验](./tpl-sva-assertions/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-sva-assertions.html) | 见 README |
| 可运行模板 | [tpl-sync-fifo-verilog：同步 FIFO 两种实现（计数器法 / 指针法）与自校验测试平台](./tpl-sync-fifo-verilog/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-sync-fifo-verilog.html) | 见 README |
| 可运行模板 | [两级触发器同步器 Verilog 模板（two_flop_sync）](./tpl-two-flop-sync-verilog/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-two-flop-sync-verilog.html) | 见 README |
| 可运行模板 | [UVM 验证平台骨架模板：可运行简化版与完整 UVM 五件套](./tpl-uvm-testbench-skeleton/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-uvm-testbench-skeleton.html) | 见 README |
| 可运行模板 | [安全状态机 Verilog 模板](./tpl-verilog-fsm-safe/) | [教程](https://geek-doc.cn/chip-design/beginner/tpl-verilog-fsm-safe.html) | 见 README |
| 排错案例 | [cocotb BinaryValue 迁移与 LogicArray 转换边界](./ts-cocotb-binaryvalue-binstr/) | [教程](https://geek-doc.cn/eda/ts-cocotb-binaryvalue-binstr.html) | 见 README |
| 排错案例 | [cocotb await 边沿误用导致挂死：最小复现工程](./ts-cocotb-fallingedge-misuse/) | [教程](https://geek-doc.cn/eda/ts-cocotb-fallingedge-misuse.html) | 日志/数据 |
| 排错案例 | [cocotb plusargs 与环境变量传参实验](./ts-cocotb-plusargs/) | [教程](https://geek-doc.cn/eda/ts-cocotb-plusargs.html) | 见 README |
| 排错案例 | [ts-cocotb-testfailed-assertion](./ts-cocotb-testfailed-assertion/) | [教程](https://geek-doc.cn/eda/ts-cocotb-testfailed-assertion.html) | 日志/数据 |
| 排错案例 | [ts-cocotb-TimeoutError-drive-read：cocotb with_timeout 超时复现实验](./ts-cocotb-TimeoutError-drive-read/) | [教程](https://geek-doc.cn/eda/ts-cocotb-TimeoutError-drive-read.html) | 见 README |
| 排错案例 | [ts-cocotb-toplevel-lang-error](./ts-cocotb-toplevel-lang-error/) | [教程](https://geek-doc.cn/eda/ts-cocotb-toplevel-lang-error.html) | 见 README |
| 排错案例 | [GTKWave VCD 解析失败复现实验](./ts-gtkwave-vcd-parse-error/) | [教程](https://geek-doc.cn/eda/ts-gtkwave-vcd-parse-error.html) | 见 README |
| 排错案例 | [Icarus Verilog unpacked array 整个 word 越界读写实验](./ts-iverilog-array-word-oob/) | [教程](https://geek-doc.cn/eda/ts-iverilog-array-word-oob.html) | 见 README |
| 排错案例 | [Icarus Verilog 不存在端口名最小复现](./ts-iverilog-cannot-find-port/) | [教程](https://geek-doc.cn/eda/ts-iverilog-cannot-find-port.html) | 日志/数据 |
| 排错案例 | [iverilog 零重复拼接最小复现](./ts-iverilog-concat-repeat-zero/) | [教程](https://geek-doc.cn/eda/ts-iverilog-concat-repeat-zero.html) | 见 README |
| 排错案例 | [iverilog always 块常量位选报错复现](./ts-iverilog-constant-select-always/) | [教程](https://geek-doc.cn/eda/ts-iverilog-constant-select-always.html) | 见 README |
| 排错案例 | [Icarus Verilog 除零与除数保护实验](./ts-iverilog-divide-by-zero/) | [教程](https://geek-doc.cn/eda/ts-iverilog-divide-by-zero.html) | 日志/数据 |
| 排错案例 | [iverilog force/release 最小对照实验](./ts-iverilog-force-release-behavior/) | [教程](https://geek-doc.cn/eda/ts-iverilog-force-release-behavior.html) | 见 README |
| 排错案例 | [Icarus Verilog fork/join 并发调度实验](./ts-iverilog-fork-join-behavior/) | [教程](https://geek-doc.cn/eda/ts-iverilog-fork-join-behavior.html) | 见 README |
| 排错案例 | [Icarus Verilog genvar 与 generate 错误最小复现](./ts-iverilog-genvar-outside-generate/) | [教程](https://geek-doc.cn/eda/ts-iverilog-genvar-outside-generate.html) | 日志/数据 |
| 排错案例 | [ts-iverilog-implicit-wire-definition：iverilog implicit definition of wire 复现](./ts-iverilog-implicit-wire-definition/) | [教程](https://geek-doc.cn/eda/ts-iverilog-implicit-wire-definition.html) | 日志/数据 + 图/波形 |
| 排错案例 | [Icarus Verilog include 搜索路径最小复现](./ts-iverilog-include-file-not-found/) | [教程](https://geek-doc.cn/eda/ts-iverilog-include-file-not-found.html) | 日志/数据 |
| 排错案例 | [Icarus Verilog invalid module item 最小复现](./ts-iverilog-invalid-module-item/) | [教程](https://geek-doc.cn/eda/ts-iverilog-invalid-module-item.html) | 见 README |
| 排错案例 | [iverilog -P 参数覆盖实验](./ts-iverilog-param-override-dashP/) | [教程](https://geek-doc.cn/eda/ts-iverilog-param-override-dashP.html) | 见 README |
| 排错案例 | [Icarus Verilog 端口 signed 转换对照实验](./ts-iverilog-port-coercion-signed/) | [教程](https://geek-doc.cn/eda/ts-iverilog-port-coercion-signed.html) | 日志/数据 |
| 排错案例 | [iverilog UDP 原语非法表项复现](./ts-iverilog-primitive-udp-error/) | [教程](https://geek-doc.cn/eda/ts-iverilog-primitive-udp-error.html) | 日志/数据 |
| 排错案例 | [Icarus Verilog `$readmemh` 相对路径与文件格式对照实验](./ts-iverilog-readmemh-file-missing/) | [教程](https://geek-doc.cn/eda/ts-iverilog-readmemh-file-missing.html) | 日志/数据 |
| 排错案例 | [Icarus Verilog $readmemh 数据格式错误最小复现](./ts-iverilog-readmemh-format-error/) | [教程](https://geek-doc.cn/eda/ts-iverilog-readmemh-format-error.html) | 日志/数据 |
| 排错案例 | [Icarus Verilog：reg 被原语或连续赋值驱动](./ts-iverilog-reg-driven-by-primitive/) | [教程](https://geek-doc.cn/eda/ts-iverilog-reg-driven-by-primitive.html) | 见 README |
| 排错案例 | [Icarus Verilog specify 块支持边界对照](./ts-iverilog-specify-block-ignored/) | [教程](https://geek-doc.cn/eda/ts-iverilog-specify-block-ignored.html) | 见 README |
| 排错案例 | [ts-iverilog-syntax-near-token：iverilog syntax error near token 三类触发](./ts-iverilog-syntax-near-token/) | [教程](https://geek-doc.cn/eda/ts-iverilog-syntax-near-token.html) | 日志/数据 |
| 排错案例 | [Icarus Verilog task/function 端口不匹配复现](./ts-iverilog-task-function-port-mismatch/) | [教程](https://geek-doc.cn/eda/ts-iverilog-task-function-port-mismatch.html) | 日志/数据 |
| 排错案例 | [ts-iverilog-unknown-module-type：iverilog "Unknown module type" 复现实验](./ts-iverilog-unknown-module-type/) | [教程](https://geek-doc.cn/eda/ts-iverilog-unknown-module-type.html) | 见 README |
| 排错案例 | [Icarus Verilog unknown system function 最小复现](./ts-iverilog-unknown-system-function/) | [教程](https://geek-doc.cn/eda/ts-iverilog-unknown-system-function.html) | 日志/数据 |
| 排错案例 | [Icarus Verilog vvp 日志与波形选项实验](./ts-iverilog-vvp-log-and-trace/) | [教程](https://geek-doc.cn/eda/ts-iverilog-vvp-log-and-trace.html) | 见 README |
| 排错案例 | [ts-opensta-clock-uncertainty](./ts-opensta-clock-uncertainty/) | [教程](https://geek-doc.cn/eda/ts-opensta-clock-uncertainty.html) | 见 README |
| 排错案例 | [ts-opensta-false-path-no-match](./ts-opensta-false-path-no-match/) | [教程](https://geek-doc.cn/eda/ts-opensta-false-path-no-match.html) | 日志/数据 |
| 排错案例 | [ts-opensta-input-delay-no-clock](./ts-opensta-input-delay-no-clock/) | [教程](https://geek-doc.cn/eda/ts-opensta-input-delay-no-clock.html) | 见 README |
| 排错案例 | [ts-opensta-liberty-not-found](./ts-opensta-liberty-not-found/) | [教程](https://geek-doc.cn/eda/ts-opensta-liberty-not-found.html) | 日志/数据 |
| 排错案例 | [OpenSTA link 找不到 cell 最小复现](./ts-opensta-link-missing-cell/) | [教程](https://geek-doc.cn/eda/ts-opensta-link-missing-cell.html) | 见 README |
| 排错案例 | [OpenSTA 最大扇出违规：最小复现与诊断对照](./ts-opensta-max-fanout-violation/) | [教程](https://geek-doc.cn/eda/ts-opensta-max-fanout-violation.html) | 日志/数据 |
| 排错案例 | [OpenSTA 最小脉宽违规：波形对照实验](./ts-opensta-min-pulse-width/) | [教程](https://geek-doc.cn/eda/ts-opensta-min-pulse-width.html) | 日志/数据 |
| 排错案例 | [ts-opensta-no-clock-startpoint](./ts-opensta-no-clock-startpoint/) | [教程](https://geek-doc.cn/eda/ts-opensta-no-clock-startpoint.html) | 见 README |
| 排错案例 | [OpenSTA no clocks found：缺失与错名对照实验](./ts-opensta-no-clocks-found/) | [教程](https://geek-doc.cn/eda/ts-opensta-no-clocks-found.html) | 日志/数据 |
| 排错案例 | [ts-opensta-report-unconstrained](./ts-opensta-report-unconstrained/) | [教程](https://geek-doc.cn/eda/ts-opensta-report-unconstrained.html) | 见 README |
| 排错案例 | [ts-opensta-sdc-syntax-error](./ts-opensta-sdc-syntax-error/) | [教程](https://geek-doc.cn/eda/ts-opensta-sdc-syntax-error.html) | 见 README |
| 排错案例 | [OpenSTA read_sdf 标注失败：实例路径与设计名对照实验](./ts-opensta-sdf-annotation-fail/) | [教程](https://geek-doc.cn/eda/ts-opensta-sdf-annotation-fail.html) | 日志/数据 |
| 排错案例 | [ts-verilator-blkseq-blocking-sequential：Verilator BLKSEQ 告警复现](./ts-verilator-blkseq-blocking-sequential/) | [教程](https://geek-doc.cn/eda/ts-verilator-blkseq-blocking-sequential.html) | 日志/数据 + 图/波形 |
| 排错案例 | [ts-verilator-multidriven-MULTIDRIVEN：Verilator MULTIDRIVEN 告警复现](./ts-verilator-multidriven-MULTIDRIVEN/) | [教程](https://geek-doc.cn/eda/ts-verilator-multidriven-MULTIDRIVEN.html) | 日志/数据 |
| 排错案例 | [ts-verilator-timing-delay-unsupported](./ts-verilator-timing-delay-unsupported/) | [教程](https://geek-doc.cn/eda/ts-verilator-timing-delay-unsupported.html) | 见 README |
| 排错案例 | [ts-verilator-undriven-UNDRIVEN：Verilator UNDRIVEN 告警复现](./ts-verilator-undriven-UNDRIVEN/) | [教程](https://geek-doc.cn/eda/ts-verilator-undriven-UNDRIVEN.html) | 日志/数据 |
| 排错案例 | [ts-verilator-unoptflat-circular-logic](./ts-verilator-unoptflat-circular-logic/) | [教程](https://geek-doc.cn/eda/ts-verilator-unoptflat-circular-logic.html) | 日志/数据 |
| 排错案例 | [ts-verilator-unusedsignal-UNUSED：Verilator UNUSEDSIGNAL/UNUSED 告警复现](./ts-verilator-unusedsignal-UNUSED/) | [教程](https://geek-doc.cn/eda/ts-verilator-unusedsignal-UNUSED.html) | 日志/数据 |
| 排错案例 | [Verilator USERWARN 与 USERERROR 最小复现](./ts-verilator-userwarn-usererror/) | [教程](https://geek-doc.cn/eda/ts-verilator-userwarn-usererror.html) | 见 README |
| 排错案例 | [Verilator ALWCOMBORDER 最小复现](./ts-verilator-warn-alwcomborder/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-alwcomborder.html) | 见 README |
| 排错案例 | [Verilator ASCRANGE 升序位选最小复现](./ts-verilator-warn-ascrange/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-ascrange.html) | 见 README |
| 排错案例 | [Verilator CONTASSREG 最小复现](./ts-verilator-warn-contassreg/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-contassreg.html) | 日志/数据 |
| 排错案例 | [Verilator DEFPARAM 最小复现](./ts-verilator-warn-defparam/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-defparam.html) | 见 README |
| 排错案例 | [Verilator EOFNEWLINE 最小复现](./ts-verilator-warn-eofnewline/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-eofnewline.html) | 见 README |
| 排错案例 | [Verilator GENUNNAMED 未命名 generate 复现](./ts-verilator-warn-genunnamed/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-genunnamed.html) | 见 README |
| 排错案例 | [Verilator IMPLICITSTATIC 最小复现](./ts-verilator-warn-implicitstatic/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-implicitstatic.html) | 见 README |
| 排错案例 | [Verilator MODDUP 同名模块重复定义复现](./ts-verilator-warn-moddup/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-moddup.html) | 见 README |
| 排错案例 | [Verilator MULTITOP 最小复现](./ts-verilator-warn-multitop/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-multitop.html) | 见 README |
| 排错案例 | [Verilator NEEDTIMINGOPT 延时处理选项对照](./ts-verilator-warn-needtimingopt/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-needtimingopt.html) | 日志/数据 |
| 排错案例 | [Verilator PINCONNECTEMPTY 最小复现](./ts-verilator-warn-pinconnectempty/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-pinconnectempty.html) | 日志/数据 |
| 排错案例 | [Verilator PINNOCONNECT 复现实验](./ts-verilator-warn-pinnoconnect/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-pinnoconnect.html) | 见 README |
| 排错案例 | [Verilator PROCASSWIRE 最小复现](./ts-verilator-warn-procasswire/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-procasswire.html) | 日志/数据 |
| 排错案例 | [Verilator REDEFMACRO 最小复现](./ts-verilator-warn-redefmacro/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-redefmacro.html) | 日志/数据 |
| 排错案例 | [Verilator TIMESCALEMOD 最小复现](./ts-verilator-warn-timescalemod/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-timescalemod.html) | 日志/数据 |
| 排错案例 | [Verilator UNOPTTHREADS 最小复现](./ts-verilator-warn-unoptthreads/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-unoptthreads.html) | 见 README |
| 排错案例 | [Verilator UNSIGNED 混合符号比较复现](./ts-verilator-warn-unsigned/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-unsigned.html) | 日志/数据 |
| 排错案例 | [Verilator WAITCONST 常量等待最小复现](./ts-verilator-warn-waitconst/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-waitconst.html) | 见 README |
| 排错案例 | [Verilator WIDTHCONCAT 最小复现](./ts-verilator-warn-widthconcat/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-widthconcat.html) | 见 README |
| 排错案例 | [Verilator WIDTHEXPAND 零扩展与符号扩展对照](./ts-verilator-warn-widthexpand/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-widthexpand.html) | 日志/数据 |
| 排错案例 | [Verilator WIDTHTRUNC 最小复现](./ts-verilator-warn-widthtrunc/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-widthtrunc.html) | 日志/数据 |
| 排错案例 | [ts-xsim-elab-timescale — xelab 报「模块缺 timescale」复现与修复](./ts-xsim-elab-timescale/) | [教程](https://geek-doc.cn/fpga/beginner/ts-xsim-elab-timescale.html) | 日志/数据 |
| 排错案例 | [ts-xsim-wave-invalid-command — XSim 报 `invalid command name "wave"`](./ts-xsim-wave-invalid-command/) | [教程](https://geek-doc.cn/fpga/beginner/ts-xsim-wave-invalid-command.html) | 日志/数据 |
| 排错案例 | [Yosys 普通读取与 formal 模式下的断言对照](./ts-yosys-assertion-ignored/) | [教程](https://geek-doc.cn/eda/ts-yosys-assertion-ignored.html) | 见 README |
| 排错案例 | [Yosys 未知模块与显式黑盒对照实验](./ts-yosys-blackbox-cell-unknown/) | [教程](https://geek-doc.cn/eda/ts-yosys-blackbox-cell-unknown.html) | 日志/数据 |
| 排错案例 | [ts-yosys-cant-open-input-file：yosys Cant open input file 复现](./ts-yosys-cant-open-input-file/) | [教程](https://geek-doc.cn/eda/ts-yosys-cant-open-input-file.html) | 日志/数据 |
| 排错案例 | [Yosys defparam 层次参数覆盖复现](./ts-yosys-defparam-not-supported/) | [教程](https://geek-doc.cn/eda/ts-yosys-defparam-not-supported.html) | 日志/数据 |
| 排错案例 | [Yosys 模块重复定义最小复现](./ts-yosys-duplicate-module-definition/) | [教程](https://geek-doc.cn/eda/ts-yosys-duplicate-module-definition.html) | 日志/数据 |
| 排错案例 | [Yosys ECP5 BRAM 推断对照实验](./ts-yosys-ecp5-bram-inference/) | [教程](https://geek-doc.cn/eda/ts-yosys-ecp5-bram-inference.html) | 见 README |
| 排错案例 | [Yosys FSM 提取对照实验](./ts-yosys-fsm-extract-fail/) | [教程](https://geek-doc.cn/eda/ts-yosys-fsm-extract-fail.html) | 见 README |
| 排错案例 | [Yosys generate 作用域名称对照实验](./ts-yosys-generate-scope-name/) | [教程](https://geek-doc.cn/eda/ts-yosys-generate-scope-name.html) | 见 README |
| 排错案例 | [Yosys iCE40 SB_IO 推断与显式例化对照](./ts-yosys-ice40-sb-io-inference/) | [教程](https://geek-doc.cn/eda/ts-yosys-ice40-sb-io-inference.html) | 日志/数据 |
| 排错案例 | [Yosys SystemVerilog interface 最小复现](./ts-yosys-interface-unsupported/) | [教程](https://geek-doc.cn/eda/ts-yosys-interface-unsupported.html) | 见 README |
| 排错案例 | [Yosys JSON 网表回读实验](./ts-yosys-json-write-read-back/) | [教程](https://geek-doc.cn/eda/ts-yosys-json-write-read-back.html) | 见 README |
| 排错案例 | [Yosys memory_map 展开对照实验](./ts-yosys-memory-replaced-by-registers/) | [教程](https://geek-doc.cn/eda/ts-yosys-memory-replaced-by-registers.html) | 日志/数据 |
| 排错案例 | [ts-yosys-multiple-clocks-always](./ts-yosys-multiple-clocks-always/) | [教程](https://geek-doc.cn/eda/ts-yosys-multiple-clocks-always.html) | 日志/数据 |
| 排错案例 | [Yosys 字符串参数静默转换复现](./ts-yosys-parameter-type-mismatch/) | [教程](https://geek-doc.cn/eda/ts-yosys-parameter-type-mismatch.html) | 日志/数据 |
| 排错案例 | [Yosys read_liberty 解析报错最小复现](./ts-yosys-read-liberty-error/) | [教程](https://geek-doc.cn/eda/ts-yosys-read-liberty-error.html) | 见 README |
| 排错案例 | [Yosys `read_verilog -sv` 不支持 package/import 最小复现](./ts-yosys-read-verilog-sv-unsupported/) | [教程](https://geek-doc.cn/eda/ts-yosys-read-verilog-sv-unsupported.html) | 日志/数据 |
| 排错案例 | [ts-yosys-techmap-loop](./ts-yosys-techmap-loop/) | [教程](https://geek-doc.cn/eda/ts-yosys-techmap-loop.html) | 日志/数据 |
| 数字设计实验 | [exp-async-fifo-cocotb-verify](./exp-async-fifo-cocotb-verify/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-async-fifo-cocotb-verify.html) | 见 README |
| 数字设计实验 | [exp-async-fifo-depth-burst-calc](./exp-async-fifo-depth-burst-calc/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-async-fifo-depth-burst-calc.html) | 见 README |
| 数字设计实验 | [exp-axi-lite-slave-cocotb](./exp-axi-lite-slave-cocotb/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-axi-lite-slave-cocotb.html) | 见 README |
| 数字设计实验 | [exp-clock-gating-yosys-compare](./exp-clock-gating-yosys-compare/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-clock-gating-yosys-compare.html) | 见 README |
| 数字设计实验 | [exp-cocotb-minimal-testbench](./exp-cocotb-minimal-testbench/) | [教程](https://geek-doc.cn/eda-lab/sim/exp-cocotb-minimal-testbench.html) | 见 README |
| 数字设计实验 | [exp-fsm-encoding-yosys](./exp-fsm-encoding-yosys/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-fsm-encoding-yosys.html) | 见 README |
| 数字设计实验 | [exp-makefile-eda-project-layout](./exp-makefile-eda-project-layout/) | [教程](https://geek-doc.cn/eda-lab/sim/exp-makefile-eda-project-layout.html) | 见 README |
| 数字设计实验 | [exp-multibit-cdc-glitch](./exp-multibit-cdc-glitch/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-multibit-cdc-glitch.html) | 见 README |
| 数字设计实验 | [exp-openlane-small-sky130-report](./exp-openlane-small-sky130-report/) | [教程](https://geek-doc.cn/eda-lab/backend/exp-openlane-small-sky130-report.html) | 日志/数据 |
| 数字设计实验 | [exp-reg-map-markdown-autogen](./exp-reg-map-markdown-autogen/) | [教程](https://geek-doc.cn/chip-design/intermediate/exp-reg-map-markdown-autogen.html) | 见 README |
| 数字设计实验 | [exp-round-robin-arbiter-sim](./exp-round-robin-arbiter-sim/) | [教程](https://geek-doc.cn/chip-design/beginner/exp-round-robin-arbiter-sim.html) | 见 README |
| 数字设计实验 | [exp-sync-fifo-verilog-iverilog](./exp-sync-fifo-verilog-iverilog/) | [教程](https://geek-doc.cn/chip-design/beginner/exp-sync-fifo-verilog-iverilog.html) | 见 README |
| 数字设计实验 | [exp-tcl-scripting-yosys-openroad](./exp-tcl-scripting-yosys-openroad/) | [教程](https://geek-doc.cn/eda-lab/synth/exp-tcl-scripting-yosys-openroad.html) | 见 README |
| 数字设计实验 | [exp-two-flop-synchronizer-mtf](./exp-two-flop-synchronizer-mtf/) | [教程](https://geek-doc.cn/chip-design/beginner/exp-two-flop-synchronizer-mtf.html) | 见 README |
| 数字设计实验 | [exp-valid-ready-handshake-wave](./exp-valid-ready-handshake-wave/) | [教程](https://geek-doc.cn/chip-design/beginner/exp-valid-ready-handshake-wave.html) | 见 README |
| 数字设计实验 | [exp-verilator-lint-error-matrix](./exp-verilator-lint-error-matrix/) | [教程](https://geek-doc.cn/chip-design/beginner/exp-verilator-lint-error-matrix.html) | 见 README |
| 数字设计实验 | [exp-waveform-png-gtkwave-surfer](./exp-waveform-png-gtkwave-surfer/) | [教程](https://geek-doc.cn/eda-lab/wave/exp-waveform-png-gtkwave-surfer.html) | 见 README |
| 数字设计实验 | [exp-yosys-verilator-quickstart](./exp-yosys-verilator-quickstart/) | [教程](https://geek-doc.cn/eda-lab/sim/exp-yosys-verilator-quickstart.html) | 见 README |
| 芯片参考与器件实验 | [74HC138 使能与地址组合穷举仿真](./chip-ref-74hc138/) | [教程](https://geek-doc.cn/chip-design/chip-ref/74hc138.html) | 日志/数据 |
| 芯片参考与器件实验 | [74HC595 移位、锁存、三态与清零行为仿真](./chip-ref-74hc595/) | [教程](https://geek-doc.cn/chip-design/chip-ref/74hc595.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-ams1117：LTspice dropout 临界与负载瞬态实测](./chip-ref-ams1117/) | [教程](https://geek-doc.cn/chip-design/chip-ref/ams1117-3-3.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-atmega328p：XSim 复现 USART 波特率发生器实测](./chip-ref-atmega328p/) | [教程](https://geek-doc.cn/chip-design/chip-ref/atmega328p.html) | 日志/数据 |
| 芯片参考与器件实验 | [CD4017 十进制计数器行为仿真](./chip-ref-cd4017/) | [教程](https://geek-doc.cn/chip-design/chip-ref/cd4017.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-ch340g：XSim 实测 UART 波特率误差失效边界](./chip-ref-ch340g/) | [教程](https://geek-doc.cn/chip-design/chip-ref/ch340g.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-esp32-wroom-32：XSim 复现 80MHz 小数分频 UART 双档实测](./chip-ref-esp32-wroom-32/) | [教程](https://geek-doc.cn/chip-design/chip-ref/esp32-wroom-32.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-lm2596：LTspice buck 功率级输出纹波实测](./chip-ref-lm2596/) | [教程](https://geek-doc.cn/chip-design/chip-ref/lm2596.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-lm358：LTspice 反相放大增益与单电源削顶实测](./chip-ref-lm358/) | [教程](https://geek-doc.cn/chip-design/chip-ref/lm358.html) | 日志/数据 |
| 芯片参考与器件实验 | [MAX485 半双工收发器行为仿真](./chip-ref-max485/) | [教程](https://geek-doc.cn/chip-design/chip-ref/max485.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-ne555：LTspice 非稳态振荡频率/占空比实测](./chip-ref-ne555/) | [教程](https://geek-doc.cn/chip-design/chip-ref/ne555.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-stm32f103c8t6：XSim 复现 USART 波特率发生器双 APB 域实测](./chip-ref-stm32f103c8t6/) | [教程](https://geek-doc.cn/chip-design/chip-ref/stm32f103c8t6.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-stm32f407vet6：XSim 实测 PLL 约束枚举与 168MHz 频计验证](./chip-ref-stm32f407vet6/) | [教程](https://geek-doc.cn/chip-design/chip-ref/stm32f407vet6.html) | 日志/数据 |
| 芯片参考与器件实验 | [chip-ref-tp4056：LTspice CC/CV 充电全程实测](./chip-ref-tp4056/) | [教程](https://geek-doc.cn/chip-design/chip-ref/tp4056.html) | 日志/数据 |
| 芯片参考与器件实验 | [常用芯片最小接线原理图（chip-ref-wiring）](./chip-ref-wiring/) | [教程](https://geek-doc.cn/chip-design/chip-ref/) | 图/波形 + 日志/数据 |
| 性能剖析 | [忙等待 vs 睡眠调度（busy-wait-vs-sleep）](./busy-wait-vs-sleep/) | [教程](https://geek-doc.cn/concepts/latency/low-latency-patterns.html) | 日志/数据 |
| 性能剖析 | [跨 NUMA 节点内存访问开销（numa-access）](./numa-access/) | [教程](https://geek-doc.cn/concepts/cpu/numa-optimization.html) | 日志/数据 |
| 性能剖析 | [SPSC / SPMC / MPSC / MPMC 消息队列基准（spsc-mpsc-queue）](./spsc-mpsc-queue/) | [教程](https://geek-doc.cn/concepts/latency/spsc-mpsc-queue.html) | 日志/数据 |
| 验证方法学 | [sby-engine-solver-missing](./sby-engine-solver-missing/) | [教程](https://geek-doc.cn/eda/ts-sby-engine-solver-missing.html) | 见 README |
| 验证方法学 | [sby-smtbmc-timeout](./sby-smtbmc-timeout/) | [教程](https://geek-doc.cn/eda/ts-sby-smtbmc-timeout.html) | 见 README |
| 验证方法学 | [SVA 断言入门：req/ack 协议的形式验证（sva-assertion-basics-sby）](./sva-assertion-basics-sby/) | [教程](https://geek-doc.cn/chip-design/verification/sva-assertion-basics-sby.html) | output/ |
| 验证方法学 | [用 SVA 给 AXI-Lite slave 做形式检查（sva-check-axi-lite-sby）](./sva-check-axi-lite-sby/) | [教程](https://geek-doc.cn/chip-design/verification/sva-check-axi-lite-sby.html) | output/ |
| 综合实验 | [AXI4 时序逐拍走查（axi4-timing-waveform-walkthrough）](./axi4-timing-waveform-walkthrough/) | [教程](https://geek-doc.cn/chip-design/intermediate/axi4-timing-waveform-walkthrough.html) | output/ |
| 综合实验 | [Codex config.toml 八字段探针](./codex-config-toml-fields/) | [教程](https://geek-doc.cn/ai-tools/codex/codex-config-toml-fields.html) | output/ |
| 综合实验 | [Verilator 覆盖率：行覆盖与翻转覆盖（coverage-types-verilator）](./coverage-types-verilator/) | [教程](https://geek-doc.cn/chip-design/verification/coverage-types-verilator.html) | output/ |
| 综合实验 | [开源 EDA 工具报错复现实验](./eda-errlog-batch1/) | [教程](https://geek-doc.cn/eda/ts-yosys-error-no-top-module.html) | 日志/数据 + 图/波形 |
| 综合实验 | [门级网表仿真（GLS）：RTL 与网表逐行比对（gls-netlist-simulation-iverilog）](./gls-netlist-simulation-iverilog/) | [教程](https://geek-doc.cn/chip-design/intermediate/gls-netlist-simulation-iverilog.html) | output/ |
| 综合实验 | [iverilog 参数绑定失败报错复现：defparam 指向不存在的参数/层级](./iverilog-cannot-bind-param/) | [教程](https://geek-doc.cn/eda/ts-iverilog-cannot-bind-param.html) | 见 README |
| 综合实验 | [iverilog 模块重复定义报错复现实验](./iverilog-duplicate-module/) | [教程](https://geek-doc.cn/eda/ts-iverilog-duplicate-module.html) | 见 README |
| 综合实验 | [iverilog inout 端口连接错误复现](./iverilog-inout-connect/) | [教程](https://geek-doc.cn/eda/ts-iverilog-inout-connect.html) | 日志/数据 |
| 综合实验 | [iverilog-numeric-truncation](./iverilog-numeric-truncation/) | [教程](https://geek-doc.cn/eda/ts-iverilog-numeric-truncation.html) | 见 README |
| 综合实验 | [iverilog 位选越界（part-select out of bound）复现实验](./iverilog-part-select-oob/) | [教程](https://geek-doc.cn/eda/ts-iverilog-part-select-oob.html) | 见 README |
| 综合实验 | [iverilog 端口位宽不匹配警告复现实验](./iverilog-port-width-mismatch/) | [教程](https://geek-doc.cn/eda/ts-iverilog-port-width-mismatch.html) | 日志/数据 |
| 综合实验 | [iverilog-sensitivity-list](./iverilog-sensitivity-list/) | [教程](https://geek-doc.cn/eda/ts-iverilog-sensitivity-list.html) | 见 README |
| 综合实验 | [iverilog timescale 继承警告复现](./iverilog-timescale-inherit/) | [教程](https://geek-doc.cn/eda/ts-iverilog-timescale-inherit.html) | 日志/数据 |
| 综合实验 | [iverilog 宏未定义报错（macro undefined）复现与修复](./iverilog-undefined-macro/) | [教程](https://geek-doc.cn/eda/ts-iverilog-undefined-macro.html) | 日志/数据 |
| 综合实验 | [iverilog 仿真跑完无波形输出（$dumpfile/$dumpvars 缺漏排查）](./iverilog-vcd-dumpvars-missing/) | [教程](https://geek-doc.cn/eda/ts-iverilog-vcd-dumpvars-missing.html) | 见 README |
| 综合实验 | [kvm-not-available-errors：KVM 不可用的三类报错与 TCG 兜底](./kvm-not-available-errors/) | [教程](https://geek-doc.cn/soc-qemu/kvm-not-available-errors.html) | 日志/数据 |
| 综合实验 | [Yosys 逻辑等价检查（LEC）：RTL vs 综合网表（lec-yosys-equiv-opt）](./lec-yosys-equiv-opt/) | [教程](https://geek-doc.cn/chip-design/intermediate/lec-yosys-equiv-opt.html) | output/ |
| 综合实验 | [openlane-antenna-violation：OpenLANE 天线违例复现与修复策略对照](./openlane-antenna-violation/) | [教程](https://geek-doc.cn/eda/ts-openlane-antenna-violation.html) | 日志/数据 |
| 综合实验 | [openlane-config-key-unknown](./openlane-config-key-unknown/) | [教程](https://geek-doc.cn/eda/ts-openlane-config-key-unknown.html) | 日志/数据 |
| 综合实验 | [openlane-fastroute-congestion：OpenLANE FastRoute 布线拥塞复现](./openlane-fastroute-congestion/) | [教程](https://geek-doc.cn/eda/ts-openlane-fastroute-congestion-fail.html) | 日志/数据 |
| 综合实验 | [openlane-magic-drc-errors：Magic 独立 DRC 间距违例复现](./openlane-magic-drc-errors/) | [教程](https://geek-doc.cn/eda/ts-openlane-magic-drc-errors.html) | 日志/数据 |
| 综合实验 | [openlane-pdk-version-mismatch](./openlane-pdk-version-mismatch/) | [教程](https://geek-doc.cn/eda/ts-openlane-pdk-version-mismatch.html) | 日志/数据 |
| 综合实验 | [openlane-pdn-pitch-error：OpenLANE PDN pitch 不对齐制造网格复现](./openlane-pdn-pitch-error/) | [教程](https://geek-doc.cn/eda/ts-openlane-pdn-pitch-error.html) | 日志/数据 |
| 综合实验 | [openlane-pl-target-density](./openlane-pl-target-density/) | [教程](https://geek-doc.cn/eda/ts-openlane-pl-target-density.html) | 日志/数据 |
| 综合实验 | [openlane-resume-from-tag](./openlane-resume-from-tag/) | [教程](https://geek-doc.cn/eda/ts-openlane-resume-from-tag.html) | 日志/数据 |
| 综合实验 | [openlane-wsl-path-issue：Docker bind mount 盘符路径报错复现](./openlane-wsl-path-issue/) | [教程](https://geek-doc.cn/eda/ts-openlane-wsl-path-issue.html) | 日志/数据 |
| 综合实验 | [param-fsm-binary-onehot](./param-fsm-binary-onehot/) | [教程](https://geek-doc.cn/chip-design/beginner/param-fsm-binary-onehot.html) | 见 README |
| 综合实验 | [qemu-command-line-annotated：一条完整 QEMU 启动命令的逐参数实验](./qemu-command-line-annotated/) | [教程](https://geek-doc.cn/soc-qemu/qemu-command-line-annotated.html) | 见 README |
| 综合实验 | [qemu-direct-kernel-initramfs：跳过引导加载器直接引导 RISC-V 内核](./qemu-direct-kernel-initramfs/) | [教程](https://geek-doc.cn/soc-qemu/qemu-direct-kernel-initramfs.html) | 日志/数据 |
| 综合实验 | [qemu-gdbstub-basics：QEMU gdbstub 握手与第一个断点实验](./qemu-gdbstub-basics/) | [教程](https://geek-doc.cn/soc-qemu/qemu-gdbstub-how-it-works.html) | 见 README |
| 综合实验 | [qemu-install-linux-distro：两大包管理体系下装齐 QEMU](./qemu-install-linux-distro/) | [教程](https://geek-doc.cn/soc-qemu/qemu-install-linux-distro.html) | 日志/数据 |
| 综合实验 | [qemu-monitor-basics：QEMU monitor 运行时观测与快照实验](./qemu-monitor-basics/) | [教程](https://geek-doc.cn/soc-qemu/qemu-monitor-basics.html) | 见 README |
| 综合实验 | [qemu-port-forwarding-hostfwd：SLIRP hostfwd 端口转发实验](./qemu-port-forwarding-hostfwd/) | [教程](https://geek-doc.cn/soc-qemu/qemu-port-forwarding-hostfwd.html) | 见 README |
| 综合实验 | [qemu-qcow2-basics：qcow2 镜像管理四组真机实验](./qemu-qcow2-basics/) | [教程](https://geek-doc.cn/soc-qemu/qemu-img-create-info-convert.html) | 见 README |
| 综合实验 | [qemu-riscv-linux-distro：QEMU 启动完整 RISC-V Linux 发行版](./qemu-riscv-linux-distro/) | [教程](https://geek-doc.cn/soc-qemu/qemu-riscv-linux-distro.html) | 日志/数据 |
| 综合实验 | [qemu-riscv-virt-first-boot：零工具链跑通第一个 RISC-V 虚拟平台](./qemu-riscv-virt-first-boot/) | [教程](https://geek-doc.cn/soc-qemu/qemu-install-first-riscv-virt.html) | 见 README |
| 综合实验 | [qemu-serial-console-wiring：三种串口控制台接线对照实验](./qemu-serial-console-wiring/) | [教程](https://geek-doc.cn/soc-qemu/qemu-serial-console-wiring.html) | 见 README |
| 综合实验 | [qemu-slirp-user-network：SLIRP 用户态网络默认行为实验](./qemu-slirp-user-network/) | [教程](https://geek-doc.cn/soc-qemu/qemu-slirp-user-network.html) | 见 README |
| 综合实验 | [qemu-system-vs-user-mode：整机模拟与单进程转译的实测对照](./qemu-system-vs-user-mode/) | [教程](https://geek-doc.cn/soc-qemu/qemu-system-vs-user-mode.html) | 日志/数据 |
| 综合实验 | [qemu-tap-bridge-network：tap 设备 + Linux bridge 二层联网](./qemu-tap-bridge-network/) | [教程](https://geek-doc.cn/soc-qemu/qemu-tap-bridge-network.html) | 日志/数据 |
| 综合实验 | [qemu-user-cross-arch-binary：x86 主机直接跑 RISC-V ELF](./qemu-user-cross-arch-binary/) | [教程](https://geek-doc.cn/soc-qemu/qemu-user-cross-arch-binary.html) | 日志/数据 |
| 综合实验 | [Quartus Lite 25.1 首个工程实战（led_blink）](./quartus-lite-first-project/) | [教程](https://geek-doc.cn/fpga/beginner/quartus-lite-first-project.html) | 日志/数据 + 图/波形 |
| 综合实验 | [sv-constraint-random-vs-cocotb](./sv-constraint-random-vs-cocotb/) | [教程](https://geek-doc.cn/chip-design/verification/sv-constraint-random-vs-cocotb.html) | output/ |
| 综合实验 | [verilator-lintoff-pragma：lint_off pragma 最小豁免实验](./verilator-lintoff-pragma/) | [教程](https://geek-doc.cn/eda/ts-verilator-lintoff-pragma.html) | 日志/数据 |
| 综合实验 | [verilator-warn-assigndly](./verilator-warn-assigndly/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-assigndly.html) | 见 README |
| 综合实验 | [Verilator BLKANDNBLK 复现实验](./verilator-warn-blkandnblk/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-blkandnblk.html) | 见 README |
| 综合实验 | [Verilator CASEOVERLAP 分支重叠复现实验](./verilator-warn-caseoverlap/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-caseoverlap.html) | 见 README |
| 综合实验 | [verilator-warn-casex 实验代码](./verilator-warn-casex/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-casex.html) | 见 README |
| 综合实验 | [verilator-warn-cmpconst](./verilator-warn-cmpconst/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-cmpconst.html) | 日志/数据 |
| 综合实验 | [verilator-warn-combdly](./verilator-warn-combdly/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-combdly.html) | 见 README |
| 综合实验 | [verilator-warn-declfilename](./verilator-warn-declfilename/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-declfilename.html) | 见 README |
| 综合实验 | [Verilator %Warning-IMPLICIT 隐式线网复现](./verilator-warn-implicit-wire/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-implicit-wire.html) | 日志/数据 |
| 综合实验 | [verilator-warn-initialdly](./verilator-warn-initialdly/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-initialdly.html) | 日志/数据 |
| 综合实验 | [verilator-warn-latch](./verilator-warn-latch/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-latch.html) | 日志/数据 |
| 综合实验 | [verilator-warn-pinmissing](./verilator-warn-pinmissing/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-pinmissing.html) | 日志/数据 |
| 综合实验 | [verilator-warn-pinnotfound](./verilator-warn-pinnotfound/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-pinnotfound.html) | 日志/数据 |
| 综合实验 | [verilator-warn-realcvt](./verilator-warn-realcvt/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-realcvt.html) | 见 README |
| 综合实验 | [verilator-warn-selrange](./verilator-warn-selrange/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-selrange.html) | 见 README |
| 综合实验 | [verilator-warn-syncasyncnet：SYNCASYNCNET 同步异步混用复现与修复](./verilator-warn-syncasyncnet/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-syncasyncnet.html) | 日志/数据 |
| 综合实验 | [verilator-warn-unusedparam](./verilator-warn-unusedparam/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-unusedparam.html) | 日志/数据 |
| 综合实验 | [Verilator VARHIDDEN 变量遮蔽警告复现实验](./verilator-warn-varhidden/) | [教程](https://geek-doc.cn/eda/ts-verilator-warn-varhidden.html) | 日志/数据 |
| 综合实验 | [yosys-check-combo-loop](./yosys-check-combo-loop/) | [教程](https://geek-doc.cn/eda/ts-yosys-check-combo-loop.html) | 见 README |
| 综合实验 | [yosys-hierarchy-check-fail](./yosys-hierarchy-check-fail/) | [教程](https://geek-doc.cn/eda/ts-yosys-hierarchy-check-fail.html) | 见 README |
| 综合实验 | [yosys-memory-not-inferred](./yosys-memory-not-inferred/) | [教程](https://geek-doc.cn/eda/ts-yosys-memory-not-inferred.html) | 见 README |
| 综合实验 | [yosys-proc-dlatch-inferred](./yosys-proc-dlatch-inferred/) | [教程](https://geek-doc.cn/eda/ts-yosys-proc-dlatch-inferred.html) | 见 README |
| 综合实验 | [yosys-read-verilog-include：Yosys include 文件找不到（Can't open include file）复现与修复](./yosys-read-verilog-include/) | [教程](https://geek-doc.cn/eda/ts-yosys-read-verilog-include.html) | 见 README |
| 综合实验 | [yosys-stat-area-zero](./yosys-stat-area-zero/) | [教程](https://geek-doc.cn/eda/ts-yosys-stat-area-zero.html) | 见 README |
| 综合实验 | [yosys-synth-top-not-set](./yosys-synth-top-not-set/) | [教程](https://geek-doc.cn/eda/ts-yosys-synth-top-not-set.html) | 见 README |
| 综合实验 | [Yosys 综合流程与 stat 报告解读（yosys-synthesis-flow-report）](./yosys-synthesis-flow-report/) | [教程](https://geek-doc.cn/chip-design/beginner/yosys-synthesis-flow-report.html) | output/ |
| 综合实验 | [yosys-warning-multiple-drivers](./yosys-warning-multiple-drivers/) | [教程](https://geek-doc.cn/eda/ts-yosys-warning-multiple-drivers.html) | 见 README |
| 综合实验 | [yosys-warning-undriven](./yosys-warning-undriven/) | [教程](https://geek-doc.cn/eda/ts-yosys-warning-undriven.html) | 见 README |
| EDA 流程实操 | [flow-cocotb-coroutines](./flow-cocotb-coroutines/) | [教程](https://geek-doc.cn/eda/flow-cocotb-coroutines.html) | 见 README |
| EDA 流程实操 | [flow-cocotb-first-test](./flow-cocotb-first-test/) | [教程](https://geek-doc.cn/eda/flow-cocotb-first-test.html) | 见 README |
| EDA 流程实操 | [flow-cocotb-makefile-flow](./flow-cocotb-makefile-flow/) | [教程](https://geek-doc.cn/eda/flow-cocotb-makefile-flow.html) | 见 README |
| EDA 流程实操 | [flow-cocotb-random-seed](./flow-cocotb-random-seed/) | [教程](https://geek-doc.cn/eda/flow-cocotb-random-seed.html) | 见 README |
| EDA 流程实操 | [开源 EDA 环境搭建（Docker 镜像一行起）](./flow-eda-env-docker-setup/) | [教程](https://geek-doc.cn/chip-design/beginner/flow-eda-env-docker-setup.html) | 见 README |
| EDA 流程实操 | [flow-git-rtl-versioning](./flow-git-rtl-versioning/) | [教程](https://geek-doc.cn/eda/flow-git-rtl-versioning.html) | 见 README |
| EDA 流程实操 | [flow-gtkwave-scripting](./flow-gtkwave-scripting/) | [教程](https://geek-doc.cn/eda/flow-gtkwave-scripting.html) | 见 README |
| EDA 流程实操 | [flow-gtkwave-vcd-analysis](./flow-gtkwave-vcd-analysis/) | [教程](https://geek-doc.cn/eda/flow-gtkwave-vcd-analysis.html) | 日志/数据 |
| EDA 流程实操 | [iverilog 编译选项实战实验](./flow-iverilog-compile-flags/) | [教程](https://geek-doc.cn/eda/flow-iverilog-compile-flags.html) | 见 README |
| EDA 流程实操 | [flow-iverilog-first-simulation：iverilog 第一次仿真最小完整流程](./flow-iverilog-first-simulation/) | [教程](https://geek-doc.cn/chip-design/beginner/flow-iverilog-first-simulation.html) | 见 README |
| EDA 流程实操 | [iverilog -g2012 SystemVerilog 子集支持矩阵探针](./flow-iverilog-g2012-sv/) | [教程](https://geek-doc.cn/eda/flow-iverilog-g2012-sv.html) | 见 README |
| EDA 流程实操 | [iverilog 多文件工程组织：最小三模块实验](./flow-iverilog-multi-file-project/) | [教程](https://geek-doc.cn/eda/flow-iverilog-multi-file-project.html) | 见 README |
| EDA 流程实操 | [flow-iverilog-regression-script](./flow-iverilog-regression-script/) | [教程](https://geek-doc.cn/eda/flow-iverilog-regression-script.html) | 见 README |
| EDA 流程实操 | [flow-iverilog-sdf-post-sim](./flow-iverilog-sdf-post-sim/) | [教程](https://geek-doc.cn/eda/flow-iverilog-sdf-post-sim.html) | 见 README |
| EDA 流程实操 | [flow-iverilog-vcd-to-gtkwave](./flow-iverilog-vcd-to-gtkwave/) | [教程](https://geek-doc.cn/eda/flow-iverilog-vcd-to-gtkwave.html) | 见 README |
| EDA 流程实操 | [flow-make-hardware-project](./flow-make-hardware-project/) | [教程](https://geek-doc.cn/eda/flow-make-hardware-project.html) | 见 README |
| EDA 流程实操 | [flow-opensta-clock-gating-check](./flow-opensta-clock-gating-check/) | [教程](https://geek-doc.cn/eda/flow-opensta-clock-gating-check.html) | 见 README |
| EDA 流程实操 | [flow-opensta-first-sta](./flow-opensta-first-sta/) | [教程](https://geek-doc.cn/eda/flow-opensta-first-sta.html) | 见 README |
| EDA 流程实操 | [flow-opensta-fix-negative-slack](./flow-opensta-fix-negative-slack/) | [教程](https://geek-doc.cn/eda/flow-opensta-fix-negative-slack.html) | 见 README |
| EDA 流程实操 | [Yosys 网表接 OpenSTA 的衔接流程（最小可复现实验）](./flow-opensta-from-yosys-netlist/) | [教程](https://geek-doc.cn/eda/flow-opensta-from-yosys-netlist.html) | 见 README |
| EDA 流程实操 | [flow-opensta-multi-corner](./flow-opensta-multi-corner/) | [教程](https://geek-doc.cn/eda/flow-opensta-multi-corner.html) | 见 README |
| EDA 流程实操 | [flow-opensta-report-checks-reading](./flow-opensta-report-checks-reading/) | [教程](https://geek-doc.cn/eda/flow-opensta-report-checks-reading.html) | 见 README |
| EDA 流程实操 | [flow-opensta-report-formats](./flow-opensta-report-formats/) | [教程](https://geek-doc.cn/eda/flow-opensta-report-formats.html) | 见 README |
| EDA 流程实操 | [flow-opensta-sdc-writing](./flow-opensta-sdc-writing/) | [教程](https://geek-doc.cn/eda/flow-opensta-sdc-writing.html) | 见 README |
| EDA 流程实操 | [flow-tcl-basics-eda](./flow-tcl-basics-eda/) | [教程](https://geek-doc.cn/eda/flow-tcl-basics-eda.html) | 见 README |
| EDA 流程实操 | [Verilator 断言开启流程最小实验](./flow-verilator-assert/) | [教程](https://geek-doc.cn/eda/flow-verilator-assert.html) | 见 README |
| EDA 流程实操 | [Verilator --binary 与 --cc 两种仿真模式对照实验](./flow-verilator-binary-mode/) | [教程](https://geek-doc.cn/eda/flow-verilator-binary-mode.html) | 见 README |
| EDA 流程实操 | [Verilator --cc 编译仿真最小实验](./flow-verilator-cc-simulation/) | [教程](https://geek-doc.cn/eda/flow-verilator-cc-simulation.html) | 见 README |
| EDA 流程实操 | [Verilator 覆盖率收集流程实验（行/分支/翻转覆盖）](./flow-verilator-coverage/) | [教程](https://geek-doc.cn/eda/flow-verilator-coverage.html) | 见 README |
| EDA 流程实操 | [Verilator 层次化编译（--hierarchical）对比实验](./flow-verilator-hierarchical/) | [教程](https://geek-doc.cn/eda/flow-verilator-hierarchical.html) | 见 README |
| EDA 流程实操 | [flow-verilator-into-ci](./flow-verilator-into-ci/) | [教程](https://geek-doc.cn/eda/flow-verilator-into-ci.html) | 见 README |
| EDA 流程实操 | [flow-verilator-lint-first](./flow-verilator-lint-first/) | [教程](https://geek-doc.cn/eda/flow-verilator-lint-first.html) | 见 README |
| EDA 流程实操 | [Verilator 多线程仿真（--threads 1/2/4）对照实验](./flow-verilator-multithread/) | [教程](https://geek-doc.cn/eda/flow-verilator-multithread.html) | 见 README |
| EDA 流程实操 | [flow-verilator-timing-model](./flow-verilator-timing-model/) | [教程](https://geek-doc.cn/eda/flow-verilator-timing-model.html) | 见 README |
| EDA 流程实操 | [Verilator 波形导出 FST/VCD 最小实验](./flow-verilator-wave-fst/) | [教程](https://geek-doc.cn/eda/flow-verilator-wave-fst.html) | 见 README |
| EDA 流程实操 | [flow-yosys-abc-mapping](./flow-yosys-abc-mapping/) | [教程](https://geek-doc.cn/eda/flow-yosys-abc-mapping.html) | 日志/数据 |
| EDA 流程实操 | [flow-yosys-check-command](./flow-yosys-check-command/) | [教程](https://geek-doc.cn/eda/flow-yosys-check-command.html) | 见 README |
| EDA 流程实操 | [flow-yosys-equiv-check](./flow-yosys-equiv-check/) | [教程](https://geek-doc.cn/eda/flow-yosys-equiv-check.html) | 见 README |
| EDA 流程实操 | [flow-yosys-first-synth](./flow-yosys-first-synth/) | [教程](https://geek-doc.cn/eda/flow-yosys-first-synth.html) | 见 README |
| EDA 流程实操 | [Yosys flatten 前后对照实验](./flow-yosys-flatten-hierarchy/) | [教程](https://geek-doc.cn/eda/flow-yosys-flatten-hierarchy.html) | 见 README |
| EDA 流程实操 | [flow-yosys-memory-inference](./flow-yosys-memory-inference/) | [教程](https://geek-doc.cn/eda/flow-yosys-memory-inference.html) | 日志/数据 |
| EDA 流程实操 | [flow-yosys-script-file](./flow-yosys-script-file/) | [教程](https://geek-doc.cn/eda/flow-yosys-script-file.html) | 见 README |
| EDA 流程实操 | [flow-yosys-stat-report-reading](./flow-yosys-stat-report-reading/) | [教程](https://geek-doc.cn/eda/flow-yosys-stat-report-reading.html) | 见 README |
| EDA 流程实操 | [flow-yosys-synth-command-anatomy](./flow-yosys-synth-command-anatomy/) | [教程](https://geek-doc.cn/eda/flow-yosys-synth-command-anatomy.html) | 日志/数据 |
| EDA 流程实操 | [flow-yosys-synth-ice40：iCE40 RTL 到比特流最小链路](./flow-yosys-synth-ice40/) | [教程](https://geek-doc.cn/eda/flow-yosys-synth-ice40.html) | 见 README |
| EDA 流程实操 | [flow-yosys-write-netlist](./flow-yosys-write-netlist/) | [教程](https://geek-doc.cn/eda/flow-yosys-write-netlist.html) | 日志/数据 |
| OpenSTA / 时序分析 | [OpenSTA create_clock 与 report_checks 最小完整流程（opensta-create-clock-report）](./opensta-create-clock-report/) | [教程](https://geek-doc.cn/chip-design/beginner/opensta-create-clock-report.html) | output/ |
| OpenSTA / 时序分析 | [OpenSTA 异步时钟：set_false_path 与 set_clock_groups 对照（opensta-false-path-async-clock）](./opensta-false-path-async-clock/) | [教程](https://geek-doc.cn/chip-design/intermediate/opensta-false-path-async-clock.html) | output/ |
| OpenSTA / 时序分析 | [OpenSTA set_input_delay / set_output_delay 对照实验（opensta-input-output-delay）](./opensta-input-output-delay/) | [教程](https://geek-doc.cn/chip-design/intermediate/opensta-input-output-delay.html) | output/ |
| OpenSTA / 时序分析 | [OpenSTA 多周期路径 set_multicycle_path 对照实验（opensta-multicycle-path-example）](./opensta-multicycle-path-example/) | [教程](https://geek-doc.cn/chip-design/intermediate/opensta-multicycle-path-example.html) | output/ |
| OpenSTA / 时序分析 | [STA setup 检查原理：逐行读一份完整报告（sta-setup-check-principle-opensta）](./sta-setup-check-principle-opensta/) | [教程](https://geek-doc.cn/chip-design/beginner/sta-setup-check-principle-opensta.html) | output/ |
| Vivado / XSim / XDC | [vivado-ambiguous-clock：多时钟 always 综合报错复现](./vivado-ambiguous-clock/) | [教程](https://geek-doc.cn/eda/ts-vivado-synth-8-91-ambiguous-clock.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-cli-batch-sim — Vivado 命令行批处理仿真（无 GUI）](./vivado-cli-batch-sim/) | [教程](https://geek-doc.cn/fpga/intermediate/vivado-cli-batch-sim.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-drc-nstd-ucio：Vivado DRC NSTD-1/UCIO-1 复现](./vivado-drc-nstd-ucio/) | [教程](https://geek-doc.cn/fpga/beginner/ts-vivado-drc-nstd-1-ucio-1-bitstream.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-force-not-supported：force/release 综合报错复现](./vivado-force-not-supported/) | [教程](https://geek-doc.cn/eda/ts-vivado-synth-8-27-force-not-supported.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-index-out-of-range：Vivado 位选越界告警复现](./vivado-index-out-of-range/) | [教程](https://geek-doc.cn/eda/ts-vivado-synth-8-324-index-out-of-range.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-inferred-latch：Vivado 推断锁存器复现](./vivado-inferred-latch/) | [教程](https://geek-doc.cn/fpga/beginner/ts-vivado-synth-8-327-inferred-latch.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-multi-driver：Vivado 2017.4 多驱动复现](./vivado-multi-driver/) | [教程](https://geek-doc.cn/fpga/beginner/ts-vivado-synth-8-3352-multiple-driver.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-named-port-not-exist：例化命名端口不存在复现](./vivado-named-port-not-exist/) | [教程](https://geek-doc.cn/eda/ts-vivado-synth-8-448-named-port-not-exist.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-rtl-to-bitstream-webpack](./vivado-rtl-to-bitstream-webpack/) | [教程](https://geek-doc.cn/fpga/beginner/exp-vivado-rtl-to-bitstream-webpack.html) | 见 README |
| Vivado / XSim / XDC | [vivado-set-property-empty：Vivado set_property 空对象复现](./vivado-set-property-empty/) | [教程](https://geek-doc.cn/fpga/beginner/ts-vivado-common-17-55-set-property.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-utilization-report-read — 综合后资源利用率报告怎么读](./vivado-utilization-report-read/) | [教程](https://geek-doc.cn/fpga/beginner/vivado-utilization-report-read.html) | 日志/数据 |
| Vivado / XSim / XDC | [vivado-xdc-timing-compare](./vivado-xdc-timing-compare/) | [教程](https://geek-doc.cn/fpga/intermediate/exp-vivado-xdc-constraints-template.html) | 见 README |
| Vivado / XSim / XDC | [vivado-xsim-design-unit](./vivado-xsim-design-unit/) | [教程](https://geek-doc.cn/fpga/beginner/ts-vivado-xsim-design-unit.html) | 见 README |
| Vivado / XSim / XDC | [vivado-xsim-timescale：XSIM 43-4099 timescale 不一致复现](./vivado-xsim-timescale/) | [教程](https://geek-doc.cn/fpga/beginner/ts-xsim-elab-timescale.html) | 图/波形 + 日志/数据 |
| Vivado / XSim / XDC | [xsim-dump-vcd-offline — 批处理 dump VCD，离线看波形](./xsim-dump-vcd-offline/) | [教程](https://geek-doc.cn/fpga/beginner/xsim-dump-vcd-offline.html) | 图/波形 + 日志/数据 |
