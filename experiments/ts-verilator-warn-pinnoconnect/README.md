# Verilator PINNOCONNECT 复现实验

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-pinnoconnect.html

本目录用同一个两输入子模块比较三类端口连接告警，并验证两种修复：

- `bad_positional.sv`：位置连接表的第二槽留空，触发 `PINNOCONNECT`。
- `boundary_empty.sv`：显式写 `.in_valid()`，触发 `PINCONNECTEMPTY`。
- `boundary_missing.sv`：命名连接表完全漏掉 `in_valid`，触发 `PINMISSING`。
- `fixed_empty.sv`：保留显式空接，并只在确有意的实例周围局部关闭 `PINCONNECTEMPTY`。
- `fixed_connected.sv`：把 `in_valid` 接到真实顶层端口。

## 运行

安装 Verilator 5.020 后，在本目录执行：

```bash
make run
```

脚本用 `-Wwarn-PINNOCONNECT` 启用这个默认关闭的代码风格告警，并用 `-Wno-DECLFILENAME` 排除文件名与模块名不同的无关提示。它逐项检查预期告警码与退出码；三个复现项出现对应告警、两个修复项 lint 退出码为 0，脚本最终才返回 0。使用 Docker 镜像时执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```
