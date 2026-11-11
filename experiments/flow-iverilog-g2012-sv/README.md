# iverilog -g2012 SystemVerilog 子集支持矩阵探针

**对应教程**：https://geek-doc.cn/eda/flow-iverilog-g2012-sv.html

用 Icarus Verilog 13.0 对 19 个 SystemVerilog 特性各写一个最小片段，`iverilog -g2012` 真编译、`vvp` 真跑，
记录哪些特性真的可用、哪些在编译期被拒绝；另附不带 `-g2012` 的默认标准对照。

## 复现

```bash
make run        # 等价 bash run.sh，需要 iverilog/vvp 13.0
```

`features/` 下一特性一片：`01_logic` 到 `19_covergroup`，其中 `08b`/`11b` 是 interface 与 case inside
的备选写法探针。预期 14 个片段打印 PASS 并退出 0，5 类特性（interface 端口、case inside、
concurrent assert property、std::randomize、covergroup）编译期报 syntax error，这正是支持范围证据。

## 说明

- 编译失败的片段不是代码错误，是 Icarus Verilog 对该 SV 特性「明确不支持」的真实输出，脚本保留原文。
- 脚本把产物写到 /tmp，不污染源码目录；`make clean` 清理。
