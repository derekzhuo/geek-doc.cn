# ts-verilator-blkseq-blocking-sequential：Verilator BLKSEQ 告警复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-blkseq-blocking-sequential.html（上线后生效）

## 环境

- eda-golden 镜像云主机（Ubuntu 22.04）：yosys 0.9 / Verilator 4.038 / iverilog 11.0
- 日期：2026-10-26；原始输出见同目录 *.log

## 复现

```bash
verilator --lint-only -Wall n3_bad.v    # 时序块用阻塞赋值触发 %Warning-BLKSEQ
verilator --lint-only -Wall n3_fixed.v  # 改非阻塞后 0 告警
iverilog -o n3_tb.vvp n3_tb.v n3_bad.v && vvp n3_tb.vvp   # 波形对拍（n3_wave.vcd）
```
