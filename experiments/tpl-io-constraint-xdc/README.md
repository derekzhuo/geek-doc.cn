# IO 约束 XDC 模板 · OpenSTA 验证实验

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-io-constraint-xdc.html

一组可直接复制的 IO 约束 XDC（SDC 同源）模板配套实验：系统同步输入、同源输出、虚拟时钟约束纯输出口，并用 OpenSTA 真实读取校验。

## 目录内容

| 文件 | 作用 |
|---|---|
| `mini.lib` | 教学用最小 liberty（BUF/NOT/AND2/OR2/DFF，单位 ns/pF），产线请替换为 PDK 库 |
| `top.v` | 最小 RTL：一组同步输入、寄存器输出、组合直达输出、纯输出口 |
| `synth.ys` | Yosys 综合脚本，映射到 `mini.lib` 生成门级网表 |
| `io_good.xdc` | 正确的 IO 约束模板（create_clock / input/output delay / uncertainty） |
| `io_bad.xdc` | 错误版：端口名 `din0` 写错，复现约束静默丢失 |
| `run_sta.tcl` / `run_sta_bad.tcl` | OpenSTA 读库、读网表、读 XDC、report_checks |
| `run_all.sh` | 容器内总控：综合 → 正确 XDC → 错误 XDC → 修正后重跑 |

## 复现方式

需要本机有 docker 且能拉取/构建 `geek-eda:0.4-flow` 镜像（Yosys 0.33 + OpenSTA 2.0.17）：

```bash
make run      # 综合 + 三轮 STA，输出里能看到 slack MET 与 port not found 警告
make synth    # 只综合，生成 top_synth.v
make sta      # 只跑正确 XDC
make sta-bad  # 只跑错误 XDC
```

注意：`mini.lib` 里的延迟数值是教学假设的常数表，仅用于演示约束如何进入时序计算，不代表任何真实工艺。
