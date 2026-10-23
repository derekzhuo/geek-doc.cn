# ts-verilator-timing-delay-unsupported

**对应教程**：https://geek-doc.cn/eda/ts-verilator-timing-delay-unsupported.html

Verilator 报 `Unsupported: Ignoring delay on this delayed statement`（STMTDLY）的最小复现与修复对照。

- `blinky_delay.v`：initial 块里写 `#10` 延时——`verilator --lint-only -Wall` 触发 STMTDLY 并以 exit 1 退出
- `blinky_fixed.v`：去掉延时、用异步复位表达初始化——lint 零告警通过（exit 0）
- `run.sh`：一键复现（本机 verilator 4.x 或 `docker run --rm -v "$PWD":/work -w /work verilator/verilator:4.038 sh run.sh`）
