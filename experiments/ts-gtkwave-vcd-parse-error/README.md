# GTKWave VCD 解析失败复现实验

**对应教程**：https://geek-doc.cn/eda/ts-gtkwave-vcd-parse-error.html（上线后生效）

本目录用 Icarus Verilog 生成正常 VCD 和无信号定义 VCD，再确定性地构造截断、残缺 header、非法时间戳与残缺变量定义，使用 GTKWave 的无界面加载模式检查解析结果。

## 复跑

在安装 GTKWave、Xvfb 与 Icarus Verilog 的 Linux 环境中执行：

```bash
bash run.sh
```

脚本会清理并重建 `build/`，打印每个加载命令、真实诊断和退出码。最后为 `$scope module tb` 补回缺失的 `$end`，再次加载验证修复。`build/` 是运行产物，不需要提交。
