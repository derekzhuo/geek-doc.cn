# OpenSTA create_generated_clock 源引脚找不到（object does not exist）

**对应教程**：https://geek-doc.cn/eda/ts-opensta-generated-clock-source-missing.html（上线后生效）

## 复现方式

本地构建或拉取含 OpenSTA 2.0.17 的镜像 `geek-eda:0.3-sta` 后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `bad.tcl`：`create_generated_clock -source` 引用了不存在的引脚 `u_buf2/CLKX`，OpenSTA 报 `pin 'u_buf2/CLKX' not found` 并中断，派生时钟没有创建；再跑 `good.tcl`：`-source` 改指真实时钟端口 `clk` 后，`report_clock_properties` 能看到主时钟 clk（10ns）与二分频派生时钟 gclk（20ns，generated）。
