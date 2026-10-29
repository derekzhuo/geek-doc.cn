# Verilator MODDUP 同名模块重复定义复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-moddup.html（上线后生效）

`broken.f` 同时读入 `pulse_dup.v` 与 `legacy_pulse.v`，两个文件都定义 `pulse_dup`，用于复现 MODDUP。`fixed.f` 移除旧副本，只保留当前实现。`run.sh` 还会验证 `--bbox-unsup` 不会消除重复模块报错。

在已安装 Verilator 5.020 的 Linux 环境运行：

```bash
bash run.sh
```

预期报错版与 `--bbox-unsup` 对照均非零退出，修复版退出码为 0，末尾输出 PASS。
