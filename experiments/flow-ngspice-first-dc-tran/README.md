# ngspice 第一次 DC 与瞬态仿真

**对应教程**：https://geek-doc.cn/eda/flow-ngspice-first-dc-tran.html

这个小实验用同一份 RC 网表完成直流工作点和瞬态分析，演示 `.cir` 文件的基本顺序、`.control` 控制块，以及 `run`、`plot`、`quit` 的最小闭环。`first_line_trap.cir` 则展示首行被当作标题后激励源未进入网表的边界情况。

## 复现

需要 Docker 和本地 `geek-eda:0.5-asic` 镜像。在本目录执行：

```bash
docker run --rm -t -v "$PWD":/work -w /work geek-eda:0.5-asic bash run.sh
```

也可以在本机已安装 ngspice 时直接执行 `bash run.sh`。主运行产生 `results/tran.data`，其中首列是时间，后两列依次为 `v(in)` 与 `v(out)`。容器内实测版本为 ngspice-42。

## 文件

- `rc_first.cir`：完整的 DC/瞬态仿真入口。
- `first_line_trap.cir`：省略标题行的边界例。
- `run.sh`：运行两种输入、打印退出码并抽取关键数据。
- `results/tran.data`：ngspice `wrdata` 导出的真实数值。
- `results/run1.log`：容器内完整运行记录，含版本、命令、退出码和边界例输出。
