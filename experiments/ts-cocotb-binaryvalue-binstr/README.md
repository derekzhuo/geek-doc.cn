# cocotb BinaryValue 迁移与 LogicArray 转换边界

**对应教程**：https://geek-doc.cn/eda/ts-cocotb-binaryvalue-binstr.html （上线后生效）

本目录包含一个 8 位计数器和两组最小 cocotb testbench。`legacy_test.py` 复现旧教程的 `BinaryValue` 导入失败；`modern_test.py` 验证 `LogicArray`、信号 `.value` 赋值、`str()` / `int()` 转换，以及含 `X` 值不能直接转整数的边界。

## 复现

需要 Docker 和本地的 `geek-eda:0.2` 镜像，镜像内需提供 cocotb 2.1.0 与 Icarus Verilog。脚本会在缺少 Python 动态库时安装 `libpython3.12-dev`，并显式设置 `LIBPYTHON_LOC`：

```bash
bash run.sh
```

脚本预期旧测试非零退出、新测试零退出，整段脚本最终零退出。若不用容器，也可在已安装 cocotb 2.1.0 与 iverilog 的环境中分别执行：

```bash
make MODULE=legacy_test
make clean
make MODULE=modern_test
```
