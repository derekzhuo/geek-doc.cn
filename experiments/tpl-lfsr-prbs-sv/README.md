# LFSR/PRBS SystemVerilog 模板实验（Galois 与 Fibonacci 两种结构）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-lfsr-prbs-sv.html （上线后生效）

用 Icarus Verilog 13.0 实测线性反馈移位寄存器：

- PRBS7（多项式 x^7+x^6+1）Galois 与 Fibonacci 周期均为 2^7-1=127，遍历 127 个独立状态；
- m 序列一个周期含 64 个 1、63 个 0；
- 全零种子锁死在 0、无法自启动（LFSR 全零陷阱）；
- PRBS15 周期实测 2^15-1=32767。

## 复现

```bash
make run
```

期望末行输出 `RESULT: ALL PASS`。

## 文件

- `lfsr.sv`：`lfsr_galois`（多输入型）与 `lfsr_fibonacci`（抽头型）
- `tb_lfsr.sv`：周期/独立状态/平衡度/全零陷阱/PRBS15 自校验平台
- `run1.log`：本机真实回归输出
