# eda-lab-verilator-binary-sim

verilator `--binary` 与 iverilog 跑同一份计数器 TB 的速度对比实验。

## 运行（Docker 主轨）

```sh
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-verilator-binary-sim geek-eda:0.1 make run
```

- `make run`：编译两套仿真器，各跑 3 次取中位数，日志在 `out/timing.log`。
- `make run-fast`：各跑 1 次（冒烟）。
- `make lint-err`：复现漏加 `--timing` 时 verilator 的报错（`out/no-timing-error.log`）。
- `make clean`：清理 `out/` 与 `obj_dir/`。

## 文件

| 文件 | 说明 |
|---|---|
| `counter.v` | 32 位计数器 DUT |
| `counter_tb.v` | 共用 TB（`#` 延迟 + `repeat @(posedge clk)`，默认 1e7 拍） |
| `scripts/timing.sh` | 计时驱动（`/usr/bin/time -p`，中位数落 `out/*_median.txt`） |
| `scripts/plot_speed.py` | matplotlib 出对比图（`out/speed_compare.svg`，数据来自实测中位数） |
| `out/timing.log` | 真实计时输出（每次 `make run` 刷新） |
