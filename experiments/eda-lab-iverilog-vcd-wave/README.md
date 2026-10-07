# eda-lab-iverilog-vcd-wave

Icarus Verilog（iverilog 12.0）下 `$dumpfile` / `$dumpvars` / `$dumpoff` / `$dumpon` / `$dumpflush` 的实操实验：
同一设计、同一激励，分别全量 dump 与「限定层级 + 跳过预热段」dump，实测两个 VCD 文件大小差异。

## 文件

| 文件 | 作用 |
|---|---|
| `counter.v` | 被测设计：`counter_top`（计数器）内嵌 `baud_gen`（波特率发生器）子模块，含若干内部信号 |
| `tb_full.v` | 全量 testbench：`$dumpvars` 无参数，dump 所有层级所有信号 → `full.vcd` |
| `tb_slim.v` | 瘦身 testbench：`$dumpvars(1, tb_slim)` 只 dump 顶层 1 层 + `$dumpoff/$dumpon` 跳过前 1000 拍 → `slim.vcd` |
| `Makefile` | `make run` 一键编译、仿真、生成大小对比 `report.txt` |

## 运行（Docker，推荐）

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-iverilog-vcd-wave geek-eda:0.1 make run
```

本机装有 iverilog 时也可以直接 `make run`。

## 产物

- `full.vcd` / `slim.vcd`：两个波形文件
- `run_full.log` / `run_slim.log`：仿真输出
- `report.txt`：文件大小、行数、信号数对比（`ls -l` / `wc -l` / `grep -c '$var'`）
- `make wavecheck`：查看 full.vcd 头部信号定义与前 300ns 跳变，供波形图校对
