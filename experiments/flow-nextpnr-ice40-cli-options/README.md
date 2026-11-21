# nextpnr-ice40 命令行参数与双器件族实验

**对应教程**：https://geek-doc.cn/eda/flow-nextpnr-ice40-cli-options.html（上线后生效）

同一份 24 位计数器 RTL 先由 Yosys 综合为一个 JSON 网表，再由 nextpnr-ice40 分别面向 iCE40UP5K-SG48 和 iCE40HX8K-CT256 完成布局布线。实验同时演示 `--json`、`--pcf`、`--package`、`--asc`、`--report`、`--freq` 和 `--seed`，并用 SG48 不存在的 99 号引脚做失败对照。

## 文件

- `top.v`、`synth.ys`：共用 RTL 与综合脚本。
- `up5k-sg48.pcf`：iCEBreaker 的 12 MHz 时钟（35）和绿色 LED（37，低电平点亮）。
- `hx8k-ct256.pcf`：Lattice iCE40-HX8K Breakout Board 的 12 MHz 时钟（J3）和 LED0（B5）。
- `up5k-sg48-bad-pin.pcf`：故意写入非法引脚 99 的失败对照。
- `results/`：两次成功运行的 JSON 报告及产物大小、SHA-256 摘要。

## 复现

安装 Docker 并取得 `geek-eda:0.4-flow` 镜像后，在本目录执行：

```bash
make
```

等价命令：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.4-flow bash ./run.sh
```

本机已安装 Yosys、nextpnr-ice40 时可执行 `make DOCKER_RUN=""`。完整日志写入 `run1.log` 和 `build/*.log`，ASC 与 JSON 报告写入 `build/`。`make clean` 只删除可重建产物，保留 `results/` 中的结果摘录。
