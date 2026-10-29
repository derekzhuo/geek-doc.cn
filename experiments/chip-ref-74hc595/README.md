# 74HC595 移位、锁存、三态与清零行为仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/74hc595.html（上线后生效）

## 实验内容

`shift_register.v` 是 74HC595 的行为级模型，包含 8 位移位寄存器、独立输出锁存器、三态输出和串行级联输出。`tb.v` 按 MSB-first 顺序移入 `8'hA6`，依次检查：

- 八个 SHCP 上升沿之后、STCP 之前，并行输出仍保持复位值；
- 一个 STCP 上升沿将 `A6` 锁存到 Q0–Q7；
- OE 为高时 Q0–Q7 进入高阻态；
- MR 为低时移位寄存器和锁存器清零。

这是数字行为仿真，不包含具体封装的传播延迟、驱动电流或模拟电气特性。

## 复现方法

环境：Windows 11 + Vivado Simulator 2017.4。确认 `run.bat` 中 Vivado 安装路径与本机一致，然后在本目录执行：

```bat
run.bat
```

脚本依次调用 `xvlog shift_register.v tb.v`、`xelab tb -s snap`、`xsim snap -R`，结束后清理仿真中间目录。成功结果应包含 `SUMMARY errors=0` 与 `PASS shift latch tristate reset`。

## 文件

- `shift_register.v`：可综合的行为模型。
- `tb.v`：带自检的测试台。
- `run.bat`：Windows 批处理运行脚本。
- `run1.log`：2026-10-30 的真实运行输出。
