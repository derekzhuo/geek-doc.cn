# Verilator UNSIGNED 混合符号比较复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-unsigned.html（上线后生效）

`unsigned_broken.sv` 将无符号计数与有符号增量相加后与零比较，触发 Verilator `UNSIGNED`。`unsigned_fixed.sv` 在运算前把两侧显式扩为 9 位有符号数，保留负值语义。

## 复现

在本目录运行（需要已有 `geek-eda:0.2` 镜像）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run
```

预期 broken 报告 `%Warning-UNSIGNED` 且退出码为 1，fixed 无诊断且退出码为 0，最终输出 `PASS`。`run1.log` 保存完整原始输出。
