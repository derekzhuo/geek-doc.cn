# CRC16 SystemVerilog 模板实验（CCITT-FALSE 与 ARC 双配置）

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-crc16-sv.html （上线后生效）

用 Icarus Verilog 13.0 验证参数化 CRC16（POLY/INIT/REFLECT）：

- CRC-16/CCITT-FALSE（0x1021/0xFFFF，MSB-first）标准向量得 0x29B1；
- CRC-16/ARC（0x8005/0x0000，反射 LSB-first，工作多项式反转成 0xA001）标准向量得 0xBB3D；
- 150 个长度 1~40 随机帧，串行/并行/软件三实现、双配置对拍；
- 40 组单比特翻转全检出，无错帧余数归零。

## 复现

```bash
make run
```

期望末行输出 `RESULT: ALL PASS`。

## 文件

- `crc16.sv`：`crc16_serial`、`crc16_parallel`，REFLECT 参数切换 MSB/LSB 两种 LFSR
- `tb_crc16.sv`：双配置自校验平台
- `run1.log`：本机真实回归输出
