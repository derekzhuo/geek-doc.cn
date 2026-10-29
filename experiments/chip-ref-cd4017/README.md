# CD4017 十进制计数器行为仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/cd4017.html（上线后生效）

本实验用 Vivado Simulator 2017.4 验证 CD4017 行为模型的十拍循环、时钟禁止、异步复位与进位关系。模型用于说明逻辑功能，不包含厂商传播延迟和电气参数；输出 `carry_n` 是实物 CARRY-OUT 的补码，在 Q0～Q4 为低、Q5～Q9 为高。

## 复现

Windows 安装 Vivado 2017.4 后，按本机安装位置修改 `run.bat` 中的工具路径，然后执行：

```bat
run.bat
```

脚本依次运行 `xvlog`、`xelab`、`xsim -R`，并清理仿真中间产物。测试台在所有检查通过时打印 `SUMMARY errors=0` 与 `PASS`。

## 文件

- `counter.v`：CD4017 行为模型。
- `tb.v`：十拍回绕、inhibit、reset 与 carry 自检。
- `run.bat`：批处理复现脚本。
- `xsim-run1.log`：2026-10-30 的真实仿真记录。
