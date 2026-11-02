# flow-verilator-timing-model

**对应教程**：https://geek-doc.cn/eda/flow-verilator-timing-model.html

Verilator 5.020 `--timing` 延时模型流程的最小复现包。

- `inv.v`：带 1ns 连续赋值延时的反相器 DUT（`assign #1 y = ~a;`）
- `tb.v`：用 `#2` 延时给激励、在电平稳定后采样的 testbench
- `event_probe.v`：`--timing` 下事件控制支持边界探针（`@(posedge clk)`、`wait(a)`、命名事件 `->e`、`fork/join`）
- `run.sh`：依次演示无选项 `--cc` 报 NEEDTIMINGOPT、`--binary --timing` 真跑延时、`--no-timing` 报 STMTDLY、事件控制探针

依赖 docker 镜像 `geek-eda:0.3-sta`（Verilator 5.020）。复现：

```bash
make run
# 或
bash run.sh
```
