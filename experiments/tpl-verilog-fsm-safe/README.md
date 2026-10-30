# 安全状态机 Verilog 模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-verilog-fsm-safe.html（上线后生效）

两段式三态状态机：正常分支完整，非法编码在一个时钟内回到 `IDLE`，恢复前 `busy` 和 `valid` 均保持安全值 0。

## 复现

安装 Icarus Verilog 后运行：

```bash
bash run.sh
```

脚本用 `-g2012 -Wall` 编译并运行 testbench。测试覆盖三个状态的转移与保持分支，并通过 `force dut.state = 2'b11` 注入非法态，检查组合输出立即归零、下一拍恢复。任一断言失败会以非零状态退出。
