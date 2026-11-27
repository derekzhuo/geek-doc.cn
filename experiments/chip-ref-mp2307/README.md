# MP2307DN：12V 转 5V 同步 buck 接线与功率级仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/mp2307.html

## 文件

- `mp2307.kicad_sch`：KiCad 10 原理图，含输入/输出电容、自举、使能、软启动、补偿、反馈分压与负载。
- `mp2307.json`：元件与网络的接线清单，便于逐脚核对；直接打开 `.kicad_sch` 不需要额外生成步骤。
- `mp2307_ripple.cir`：12V 输入、约 2A 电阻负载下的稳态开关仿真。
- `mp2307_load_step.cir`：相同固定占空比功率级上的 1A→2A 被动负载阶跃。
- `results/`：KiCad ERC 报告与 LTspice 原始测量日志。

## 复现

### KiCad 10

用原理图编辑器打开 `mp2307.kicad_sch`，或在已配置 `kicad-cli` 的 Windows 环境运行：

```bat
run-kicad.bat
```

本次验收结果为 0 Errors、0 Warnings。KiCad 10 标准库没有 MP2307 独立符号，图中借用 `Regulator_Switching:MP2303ADN` 的图形：两者 1–8 脚名称、顺序和 SOIC-8EP 封装一致，实例 Value 已改为 `MP2307DN`。另补第 9 脚 EP 并接 GND，分配 `Package_SO:SOIC-8-1EP_3.9x4.9mm_P1.27mm_EP2.41x3.3mm` 封装。借用仅限图形，不表示两颗芯片的电气参数相同。

### LTspice 26.1.1

Windows 默认安装位置下运行：

```bat
run-ltspice.bat
```

也可以在 LTspice 已加入命令行路径时分别执行：

```bash
LTspice.exe -b mp2307_ripple.cir
LTspice.exe -b mp2307_load_step.cir
```

生成的 `.raw` 是中间文件；关键 `.meas` 结果写入同名 `.log`。仓库 `results/` 保留了本次输出。

## 模型与结果边界

模型使用 340kHz 固定频率、上下管各 100mΩ、每次换相 100ns 死区、10µH/20mΩ 电感、两只 22µF/5mΩ 输出电容与可选肖特基。稳态模型得到输出均值约 5.007V、输出纹波约 7.695mVpp、电感电流纹波约 0.872A。开环阶跃模型得到阶跃前约 5.122V、恢复后约 5.007V，窗口最低约 4.617V，电感峰值约 3.113A。

这是用于研究功率级 CCM、纹波和被动负载阶跃的固定占空比模型，不含 MP2307 的反馈补偿、软启动、UVLO、限流和热保护。它不能用于证明真片闭环瞬态、补偿稳定性或保护阈值；12kΩ/3.9nF 补偿网络只出现在接线图中，没有接入这两个开关模型。
