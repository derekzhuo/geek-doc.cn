# vivado-axi-stream-backpressure

**对应教程**：<https://geek-doc.cn/fpga/intermediate/vivado-axi-stream-backpressure.html>（随对应教程上线后生效）

用一组一项深度的 AXI-Stream 寄存缓冲观察 `valid/ready` 握手。实验覆盖连续输入、隔拍气泡和下游反压三种流量，并检查数据顺序、传输总数以及反压期间输出 `valid/data` 的稳定性。

## 复现（Windows，Vivado/XSim 2017.4）

```powershell
powershell -ExecutionPolicy Bypass -File run-axis.ps1
```

工具路径在脚本顶部，按本机安装位置修改。脚本依次执行 `xvlog`、`xelab` 和 `xsim`，把编译与仿真日志收进 `axis-results.zip`。

测试台对 96 个输入字建立顺序参考队列。只有同一时钟沿上的 `valid && ready` 才计为一次传输；反压分支先连续四拍撤销 `ready`，再按两拍接收、一拍暂停的模式恢复。三组各传输 32 字，全部检查通过才输出 `AXIS_SCENARIOS_PASS transfers=96`。

该实验验证这一寄存缓冲的握手语义，不代表任意 AXI-Stream 组件都能提供相同的吞吐或缓冲能力。

## 本次实测

2026-11-22 在 Windows 节点使用 Vivado/XSim 2017.4 完成。连续输入、隔拍气泡和下游反压三组各完成 32 次有序传输，总计 96 次；反压期间输出 `valid/data` 稳定性检查通过，日志未出现顺序或稳定性错误。结果保存在 `results/`。公开文本仅将本地工作目录替换为 `<workdir>`，并统一换行与行尾空白。
