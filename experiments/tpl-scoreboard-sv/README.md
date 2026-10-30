# SystemVerilog 记分板模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-scoreboard-sv.html（上线后生效）

这个最小实验用一个单拍寄存器作为被测设计，演示有序期望队列、四态比较、错误计数和仿真退出状态。正常组应返回 0；`+INJECT_MISMATCH` 组故意制造一次数据不一致，`vvp` 应返回非零。

## 运行

需要 Icarus Verilog 13.0 或兼容的 SystemVerilog 仿真器：

```bash
bash run.sh
```

脚本先运行正常组，再运行注错组。只有正常组返回 0 且注错组返回非零，脚本自身才返回 0；编译产物在退出时自动删除。

也可以分别运行：

```bash
iverilog -g2012 -s tb_scoreboard -o .tb_scoreboard.vvp scoreboard_dut.sv tb_scoreboard.sv
vvp .tb_scoreboard.vvp
vvp .tb_scoreboard.vvp +INJECT_MISMATCH
rm -f .tb_scoreboard.vvp
```
