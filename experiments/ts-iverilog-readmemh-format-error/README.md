# Icarus Verilog $readmemh 数据格式错误最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-readmemh-format-error.html（上线后生效）

本目录包含非法十六进制字符、越界显式地址和修复后数据三组对照。测试平台把存储器预置为 `xx`，以便区分数据文件未成功写入与加载了合法零值。

## 复现

需要 Icarus Verilog 13.0 或兼容版本。在本目录执行：

```bash
bash run.sh
```

脚本编译一次 `tb.sv`，依次运行 `bad-char.hex`、`bad-address.hex` 和 `fixed.hex`，保留每次 `vvp` 的退出码，最后核对修复数据的 `mem[2]` 是否为 `22`。`run1.log` 是在 macOS 26.5.2 x86_64、Icarus Verilog 13.0 下由同一脚本产生的合并标准输出与标准错误记录。

## 文件

- `tb.sv`：8 项、每项 8 位的存储器与 `$readmemh` 测试平台。
- `bad-char.hex`：第 3 个数据词含非法字符 `G`。
- `bad-address.hex`：在只有地址 0 到 7 的存储器中显式写入地址 8。
- `fixed.hex`：合法数据，去掉非法字符与越界地址。
- `run1.log`：真实复现与修复复跑记录。
