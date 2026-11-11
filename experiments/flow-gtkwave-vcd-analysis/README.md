# flow-gtkwave-vcd-analysis

**对应教程**：https://geek-doc.cn/eda/flow-gtkwave-vcd-analysis.html

GTKWave 波形分析流程的最小实验：深度 4 的同步 FIFO 配合两份 testbench 激励（A 快排空、B 慢排空）产出两份 VCD，再用 `gtkwave -S` 的 Tcl 批处理完成 SST 正则搜索、沿查找、主/baseline marker 测距、缩放、值翻译过滤器、信号高亮、双 VCD 标签页对照与 save 文件落盘；全程在 `geek-eda:0.4-flow` 容器的 Xvfb 下完成，无需真实显示器。

## 文件

- `sync_fifo.v`：教学用同步 FIFO（深度 4、位宽 8，引出 fire_wr/fire_rd 握手线）
- `tb_fifo.v`：testbench，`+MODE=A/B` 切换快慢两种消费者节奏，分别导出 `wave_a.vcd`、`wave_b.vcd`
- `analyze.tcl`：分析主脚本（搜索/沿/marker/缩放/过滤/高亮/双标签/save）
- `export_full.tcl`：按环境变量 `SCENE=A|B` 导出对应场景的 full、fire_rd 跳变表
- `gaps_b.tcl`：场景 B 的读握手上升沿间隔测量
- `timedim.tcl`：复现 3.3.116 无头模式下时间维度菜单命令 SIGSEGV（rc=139）
- `cnt_filter.txt`：FIFO 占用量值翻译表（EMPTY/W1..W3/FULL）
- `run.sh`：八段全流程，每步起一个 `--rm` 容器执行，gtkwave 调用用 `timeout 60s` 包裹

## 复现

依赖本机 Docker，且已加载镜像 `geek-eda:0.4-flow`（含 iverilog 12.0、gtkwave 3.3.116、Xvfb）。

```bash
bash run.sh
```

产物（不入库）：`sim.vvp`、`wave_a.vcd`、`wave_b.vcd`、`full_{a,b}.txt`、`firerd_{a,b}.txt`、`analysis.gtkw`、`step4.raw`。
