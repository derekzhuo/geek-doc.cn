# Verilator PINCONNECTEMPTY 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-pinconnectempty.html（上线后生效）

`top_bad.v` 用显式空连接 `.debug()` 复现 `%Warning-PINCONNECTEMPTY`；`top_fixed.v` 把该输出接到具名未用线网 `unused_debug`，保留清晰的设计意图。

## 运行

需要 Docker 和本机已有镜像 `geek-eda:0.2`（Verilator 5.020）。在本目录执行：

```bash
./run.sh
```

脚本预期报错版非零退出、修复版零退出，最后打印 `PASS`。`run1.log` 是同一次运行的完整原始输出。
