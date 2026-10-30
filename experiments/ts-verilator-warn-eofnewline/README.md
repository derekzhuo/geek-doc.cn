# Verilator EOFNEWLINE 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-eofnewline.html（上线后生效）

`eofnewline.sv` 的最后一个字节是分号，不是换行符；`eofnewline_fixed.sv` 仅在文件末尾多一个 LF。两个空模块用于隔离告警，避免位宽、未使用信号等其他检查干扰结果。

## 复现

需要 Docker 与本地 `geek-eda:0.2` 镜像。在本目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本先确认无末尾换行的源文件触发 `EOFNEWLINE` 且返回非零，再检查补上末尾换行的源文件通过 lint，成功时输出 `PASS`。
