# Verilator MULTITOP 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-multitop.html（上线后生效）

`multitop.sv` 含有互不例化的 `chip_top` 与 `debug_top`。脚本先复现未指定顶层时的 `MULTITOP`，再以 `--top-module chip_top` 复跑 lint，并用 XML 输出核对未选中的顶层已不在层级中。

在已安装 Verilator 5.020 的 Linux 环境执行：

```bash
make run
```

也可使用教程所述的 `geek-eda:0.2` 容器运行同一目标。
