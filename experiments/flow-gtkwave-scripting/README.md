# flow-gtkwave-scripting

**对应教程**：https://geek-doc.cn/eda/flow-gtkwave-scripting.html

GTKWave 脚本化查看流程的最小实验：iverilog 跑出 VCD，再用 `gtkwave -S` 的 Tcl 批处理加信号、导出信号清单与跳变数据表、写 `.gtkw` save 文件；全程在 `geek-eda:0.3-sta` 容器的 Xvfb 下完成，无需真实显示器。

## 文件

- `counter.v`：8 位复位计数器（被测设计）
- `tb_counter.v`：testbench，`$dumpvars(0, tb_counter)` 全层次导出 `wave.vcd`
- `export.tcl`：GTKWave Tcl 脚本（addSignalsFromList / getNumFacs / signalChangeList / Write Save File）
- `run.sh`：九步全流程，每步起一个容器执行
- `Makefile`：`make run` / `make clean`

## 复现

依赖本机 Docker，且已加载镜像 `geek-eda:0.3-sta`（含 iverilog 12.0、gtkwave 3.3.116、Xvfb）。

```bash
make run
```

产物（不入库，`make clean` 可清）：`wave.vcd`、`layout.gtkw`、`facs.txt`、`cnt_changes.txt`、`load.out`。
