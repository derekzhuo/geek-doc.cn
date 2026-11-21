# nextpnr-iCE40 布局种子扫描实验

**对应教程**：https://geek-doc.cn/eda/flow-nextpnr-ice40-seed-sweep.html（上线后生效）

本实验固定同一份 Yosys JSON 网表、iCE40 HX1K-TQ144 器件与封装、PCF 引脚约束和 50 MHz 时序目标，只改变 nextpnr 的 `--seed`，依次运行 0、1、2、3、4 五轮。设计是一个带异步低有效复位的 24 位计数器。

## 复现

需要 Docker 与 `geek-eda:0.4-flow` 镜像。在本目录执行：

```bash
make run
```

脚本只综合一次，生成 `build/top.json`，随后执行五条等价于下面的命令：

```bash
nextpnr-ice40 --hx1k --package tq144 \
  --json build/top.json --pcf top.pcf --freq 50 \
  --seed 0 --asc results/top-seed-0.asc
```

其余四轮仅替换种子和输出文件名。`scripts/summarize.py` 从完整日志提取布局后与布线后的 Fmax、资源利用率、路由弧数、拆线重绕数、剩余弧数、退出状态及 ASC 哈希；不会估算日志中不存在的指标。

## 本次结果

- 工具：Yosys 0.33、nextpnr-ice40 0.6-3build5、Python 3.12.3。
- 输入 JSON SHA-256：`44e1e58a44ca34acfa4b1ebf30dcd242082c20656cc5d2c6b1d6bf3b68c5cbd0`。
- 五轮都以状态码 0 正常结束，布线后 Fmax 均为 194.33 MHz，对 50 MHz 目标均为 PASS。
- 每轮使用 28/1280 个 ICESTORM_LC、6/112 个 SB_IO、2/8 个 SB_GB；路由 85 条弧，最终剩余弧数均为 0。
- seed 0 有 1 条弧经历拆线重绕，seed 1 至 4 为 0；五份 ASC 的 SHA-256 均不同。

这只是一份低占用小设计的五次采样，不能据此推出更大设计或更高利用率下也会得到相同 Fmax。

## 文件

- `top.v`、`top.pcf`、`synth.ys`：固定 RTL、引脚约束和 JSON 生成脚本。
- `run.sh`：一次综合、五轮布局布线、输入哈希核验与汇总入口。
- `results/nextpnr-seed-*.log`：五份完整布局布线日志。
- `results/top-seed-*.asc`：五份 ASCII 配置流产物。
- `results/summary.csv`、`results/summary.json`：机器可读汇总。
- `results/yosys-synth.log`、`results/tool-versions.txt`：综合记录与工具版本。
- `scripts/plot_seed_sweep.py`：从 `summary.csv` 重绘 Fmax 与拆线重绕图，需要 matplotlib。

如需重绘图片：

```bash
python3 scripts/plot_seed_sweep.py \
  --csv results/summary.csv --output seed-sweep.svg
```

`make clean` 会删除重新生成的 `build/` 与 `results/`，需要保留本次记录时请先另行复制。
