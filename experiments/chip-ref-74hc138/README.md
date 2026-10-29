# 74HC138 使能与地址组合穷举仿真

**对应教程**：https://geek-doc.cn/chip-design/chip-ref/74hc138.html（上线后生效）

用行为级 Verilog 描述 74HC138 的三个使能输入、三位地址输入和八路低有效输出，并在 Vivado Simulator 2017.4 中遍历全部 64 种输入组合。

## 文件

- `decoder.v`：74HC138 组合逻辑行为模型。
- `tb.v`：穷举 64 组输入并逐组比对期望输出的测试台。
- `run.bat`：Windows 下调用 xvlog、xelab、xsim 的运行脚本。
- `run1.log`：2026-10-30 在 Windows worker / Vivado XSim 2017.4 上得到的原始输出。

## 复现

将 `run.bat` 中 Vivado 2017.4 的安装路径改成本机路径，在本目录执行：

```bat
run.bat
```

预期摘要为 `SUMMARY vectors=64 errors=0` 和 `PASS all address and enable combinations`。本实验只验证逻辑真值关系，不测量传播延迟、驱动电流或电气电平。
