# Icarus Verilog fork/join 并发调度实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-fork-join-behavior.html（上线后生效）

这个最小测试平台用带时间戳的输出对照 `fork/join`、`fork/join_any`、`fork/join_none` 和 `disable fork`，并在最后一个用例中让父 `initial` 块直接结束，观察分离子进程完成前仿真是否保持运行。源码没有调用 `$finish`。

## 复现

安装 Icarus Verilog 后，在本目录执行：

```bash
bash run.sh
```

脚本使用 `iverilog -g2012 -Wall -s tb` 编译，再用 `vvp` 运行。实验基于 Icarus Verilog 13.0；时间单位由测试平台中的 `` `timescale 1ns/1ps `` 指定。
