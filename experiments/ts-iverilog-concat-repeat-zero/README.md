# iverilog 零重复拼接最小复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-concat-repeat-zero.html（上线后生效）

## 文件

- `broken.v`：`EXTRA=0` 时无条件生成重复拼接，复现编译错误。
- `fixed.v`：用条件 `generate` 分开零次与正数次分支。
- `tb.v`：同时检查 `EXTRA=0` 与 `EXTRA=2` 的输出。
- `run.sh`：依次复现错误、编译修复版并运行测试。

## 复现

需要 Icarus Verilog 13.0。在本目录运行：

```bash
bash run.sh
```

预期第一段以状态 2 结束并报告重复次数为零；第二段编译成功，仿真分别打印 `EXTRA=0` 与 `EXTRA=2` 的 PASS。
