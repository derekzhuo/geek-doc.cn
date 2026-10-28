# iverilog 位选越界（part-select out of bound）复现实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-part-select-oob.html

## 复现

```bash
# 默认编译：无任何提示，仿真输出 xx
iverilog -o simv top.v && vvp simv

# 打开 select-range 警告：越界位选现身
iverilog -Wselect-range -o simv top.v && vvp simv

# 修复后：零警告，仿真 PASS
iverilog -Wselect-range -o simv_fixed top_fixed.v && vvp simv_fixed
```

- `top.v`：8 位寄存器 `data` 被位选 `[15:8]`，越界部分被替换为 `'bx`。
- `top_fixed.v`：声明扩到 `[15:0]`，位选合法，`high_byte` 得到期望值 `8'hA5`。
