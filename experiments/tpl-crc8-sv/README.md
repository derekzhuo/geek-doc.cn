# CRC8 SystemVerilog 模板实验（逐位 LFSR vs 字节并行）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-crc8-sv.html （上线后生效）

用 Icarus Verilog 13.0 对两份 CRC8 实现（CRC-8/SMBUS，POLY=0x07、INIT=0x00）做自校验回归：

- 标准校验向量 "123456789" 必须得到 0xF4；
- 200 个长度 1~32 的随机帧，串行、并行、软件参考模型三方逐拍对拍；
- 50 组单比特翻转全部被检出（CRC8 汉明距离保证）；
- 无错帧追加 CRC 后余数归零。

## 复现

```bash
make run
```

期望末行输出 `RESULT: ALL PASS`。

## 文件

- `crc8_serial.sv`：`crc8_serial`（逐位 LFSR，1 比特/拍）与 `crc8_parallel`（1 字节/拍）
- `tb_crc8.sv`：自校验测试平台（标准向量 + 随机对拍 + 检错 + 余数归零）
- `run1.log`：本机真实回归输出
