# Quartus Lite 25.1 首个工程实战（led_blink）

> **对应教程**：https://geek-doc.cn/fpga/beginner/quartus-lite-first-project.html

用 Quartus Prime Lite 25.1 批处理 Tcl 全流程：新建工程 → 指定器件 EP4CE6E22C8（Cyclone IV E，Lite 免费档）→ 添加 Verilog 源码 → 引脚/电平约束 → `execute_flow -compile` 全编译 → 摘 Fitter 资源报告。

## 复现方式

Windows 下把 `led_blink.v`、`flow.tcl` 放同一目录，然后：

```bat
<Quartus安装目录>\quartus\bin64\quartus_sh.exe -t flow.tcl
```

编译产物（sof、pof、报告）落在当前目录与 `output_files/`；`led_blink.fit.summary` 是资源占用摘要。

## 文件说明

| 文件 | 作用 |
|---|---|
| `led_blink.v` | LED 闪烁顶层：50MHz 时钟 25_000_000 分频，约 0.5Hz 翻转 |
| `flow.tcl` | 一键建工程 + 全编译脚本（器件/引脚/电平全在脚本里） |
| `compile-full.log` | 本实验在 Quartus Lite 25.1std.0.1129 上的真实编译日志 |
| `qgui.png` | Quartus GUI 打开工程的真机截图 |
