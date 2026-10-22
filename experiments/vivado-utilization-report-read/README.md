# vivado-utilization-report-read — 综合后资源利用率报告怎么读

**对应教程**：https://geek-doc.cn/fpga/beginner/vivado-utilization-report-read.html（极客工场站点对应篇目，上线后此链接即生效）

**实测数字**（Vivado 2017.4，器件 xc7a35tcpg236-1，2026-10-22 真机综合）：

| 设计 | Slice LUTs | Slice Registers | F7/F8 Muxes | Bonded IOB |
|---|---|---|---|---|
| counter4（4 位计数器） | 3 | 4 | 0/0 | 6 |
| fifo16x8（16×8 同步 FIFO） | 63 | 149 | 16/8 | 24 |

可用量：LUT 20800 / Register 41600 / IOB 106——计数器占 0.01%，FIFO 占 0.30%。

**文件**

| 文件 | 作用 |
|---|---|
| `counter4.v` | 4 位计数器（最小设计） |
| `fifo16x8.v` | 16 深 8 宽同步 FIFO（含 almost_full/empty 标志） |
| `synth_counter.tcl` / `synth_fifo.tcl` | 批处理综合脚本（把 `<本目录>` 换成实际路径） |
| `util_counter4.rpt` / `util_fifo16x8.rpt` | 真实 report_utilization 输出 |

**复现**：装好 Vivado 2017.4（或更新版）后，在本目录跑
`vivado -mode batch -source synth_counter.tcl`（Windows 用 `vivado.bat`），
报告写到 `util_counter4.rpt`；FIFO 同理。器件型号在 tcl 里改 `-part` 即可换。
