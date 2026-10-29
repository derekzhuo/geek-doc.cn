# Verilator NEEDTIMINGOPT 延时处理选项对照

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-needtimingopt.html（上线后生效）

这个最小实验用同一份含 `#10` 的 SystemVerilog 源码比较三种调用：不指定延时策略、显式传入 `--timing`、显式传入 `--no-timing`。脚本同时记录诊断和退出码，避免只凭告警文字判断是否通过。

## 运行

本机安装 Verilator 5.x 时：

```bash
make run
```

使用教程同款容器时，在本目录执行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run
```

Verilator 5.020 的预期结果是：默认调用报告 `NEEDTIMINGOPT` 并退出 1；`--timing` 无诊断并退出 0；`--no-timing` 报告忽略延时的 `STMTDLY`，在 `-Wall` 默认告警致错策略下退出 1。三项均被脚本核对后才会输出 `PASS`。

`run1.log` 保存本次完整原始输出，三行头部记录容器命令、日期与工具链。
