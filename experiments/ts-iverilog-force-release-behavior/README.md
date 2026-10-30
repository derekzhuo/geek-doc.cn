# iverilog force/release 最小对照实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-force-release-behavior.html （教程上线后生效）

这个测试台同时强制一个 `reg` 和一个由连续赋值驱动的 `wire`，在强制期间改变 wire 的上游驱动，再释放两者。输出用于对照两条语义：reg 释放后保持强制值，直到下一次过程赋值；net 释放后恢复当前驱动值。

## 运行

需要 Icarus Verilog 13.0 与 Bash。在本目录执行：

```bash
bash run.sh
```

脚本使用 `iverilog -g2012 -s tb -o simv tb.v && vvp simv` 完成编译与仿真，退出时删除临时 `simv` 文件。重点比较 `step=forced_driver_0`、`step=released` 和 `step=reg_reassigned` 三行。
