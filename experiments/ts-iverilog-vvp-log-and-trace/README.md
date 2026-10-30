# Icarus Verilog vvp 日志与波形选项实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-vvp-log-and-trace.html（上线后生效）

本目录对照 `vvp -l`、选项位置、VCD dump 系统任务和 `-lxt2` 参数的实际行为。

## 复现

安装 Icarus Verilog 后执行：

```bash
bash run.sh
```

`tb.v` 使用 `$dumpfile` 和 `$dumpvars` 生成波形，`no_dump.v` 不包含这两个系统任务。脚本把各次运行的终端输出、退出状态、日志文件内容和波形文件类型依次打印出来。

实验以 Icarus Verilog 13.0 / macOS 为准。本文记录的是该版本的行为，不把未在 `vvp -h` 中列出的参数当作可移植接口。
