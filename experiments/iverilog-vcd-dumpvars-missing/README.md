# iverilog 仿真跑完无波形输出（$dumpfile/$dumpvars 缺漏排查）

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-vcd-dumpvars-missing.html（文档上线后生效）

三个 testbench 复现「iverilog 仿真正常结束但拿不到波形」的两类典型现场：

- `tb_blink_nodump.v`：testbench 忘写 `$dumpvars`，`vvp` 跑完目录里没有任何 VCD 文件；
- `tb_blink_dumpoff.v`：写了 `$dumpvars` 但开头 `$dumpoff` 之后忘记 `$dumpon`，VCD 只有信号定义头、没有任何波形数据；
- `tb_blink.v`：修复版，`$dumpfile` + `$dumpvars(0, tb_blink)`，复跑生成完整 `blink.vcd`。

## 复现方式

```bash
make nodump    # 场景一：无 VCD 生成
make dumpoff   # 场景二：VCD 空壳（只有 20 行头部）
make fixed     # 修复版：blink.vcd 含完整翻转记录
```

工具：Icarus Verilog 13.0（`iverilog -V` 可查）。
