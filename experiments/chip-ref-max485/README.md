# MAX485 半双工收发器行为仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/max485.html（上线后生效）

本实验用 Vivado Simulator 2017.4 验证 MAX485 行为模型的正向驱动、反向换向、双驱动冲突与总线释放。模型用于说明方向控制和差分总线逻辑，不模拟真实收发器电气阈值、传播延迟或模拟 contention 电流。

## 复现

Windows 安装 Vivado 2017.4 后，按本机安装位置修改 `run.bat` 中的工具路径，然后执行：

```bat
run.bat
```

脚本依次运行 `xvlog`、`xelab`、`xsim -R`，并清理仿真中间产物。测试台逐场景打印 PASS，末尾汇总 `SUMMARY errors=0`。

## 文件

- `transceiver.v`：MAX485 行为模型。
- `tb.v`：双节点方向切换、冲突和释放测试。
- `run.bat`：批处理复现脚本。
- `xsim-run1.log`：2026-10-30 的真实仿真记录。
