# Icarus Verilog specify 块支持边界对照

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-specify-block-ignored.html（上线后生效）

这组实验用同一个输入分别驱动带 specify 路径延迟的缓冲器和带显式连续赋值延迟的缓冲器，再对带 setup/hold 检查的 D 触发器施加违例与合规激励。

## 复现

安装 Icarus Verilog 13.0 后，在本目录执行：

```bash
bash run.sh
```

脚本依次编译并运行 `tb_path.v` 与 `tb_timing.v`。`tb_path` 比较 7 ns 模块路径延迟和 `assign #7`；`tb_timing` 比较建立时间违例、保持时间违例与合规边沿。仿真产物 `simv_path`、`simv_timing` 可直接删除并重新生成。
