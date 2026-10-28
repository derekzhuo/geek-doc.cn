# verilator-warn-syncasyncnet：SYNCASYNCNET 同步异步混用复现与修复

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-syncasyncnet.html

## 文件

- `syncasync_bad.v`：反例——`rst_n` 一路当异步复位（`negedge` 敏感表），另一路在 `always @(posedge clk)` 里被当时钟使能同步读取，触发 `%Warning-SYNCASYNCNET`。
- `syncasync_fixed.v`：修复——`rst_n` 专职异步复位；需要同步读到的复位状态先经两级触发器同步器打拍成 `rst_n_sync` 再被采样。
- `run1.log`：Verilator 5.020 lint 实测记录（报错版退出码 1、修复版退出码 0）。

## 复现

```bash
verilator --lint-only -Wall syncasync_bad.v     # 复现告警，退出码 1
verilator --lint-only -Wall syncasync_fixed.v   # 修复后复验，退出码 0
```

无本地 Verilator 时可用容器跑：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 verilator --lint-only -Wall syncasync_bad.v
```
