# flow-openroad-congestion-tuning

**对应教程**：https://geek-doc.cn/eda/flow-openroad-congestion-tuning.html（上线后生效）

用同一个 32 单元交叉网表，对 OpenROAD 全局布局的目标密度做两轮对照。基线密度为 0.95，调参轮为 0.45；网表、布图、端口、层资源、全局布线迭代预算和详细布线参数均保持不变。

## 复现

准备 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
make run
# 等价于
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

已有 OpenROAD 26Q4 命令时，也可以直接执行 `bash run.sh`，或用 `OR_BIN` 指定可执行文件。

## 输入与固定条件

- `fixtures/top.v`：32 个 `BUF_X1`、64 条两点信号网，输入与输出交叉连接。
- `fixtures/tech.lef`：三层教学金属层；`fixtures/stdcell.lef` 和 `fixtures/teaching.lib` 提供配套单元抽象。
- `scripts/route.tcl`：16×16um die、12×12um core，metal1–metal3 的全局布线资源调整系数均为 0.4，布线轨道间距 0.28um。
- 两轮都执行 `global_placement`、`detailed_placement`、`global_route` 和 `detailed_route`。全局布线使用 `-congestion_iterations 10 -allow_congestion`，详细布线使用 `-droute_end_iter 10`。
- 唯一对照变量是 `global_placement -density`：0.95 与 0.45。

## 结果与判定

`run.sh` 分别执行两轮，检查结束标记、guide、拥塞摘要和 DRC 报告，再从最终 `Total ... Max H / Max V / Total Congestion` 行与 DRC 条目数计算结果。脚本要求调参轮全局布线拥塞量低于基线且降为 0，同时详细布线 DRC 数下降；任一条件不满足都会返回非零状态。

本次结果为：基线拥塞量 3、DRC 36 条，调参轮拥塞量 0、DRC 7 条。`results/summary.rpt` 保存这两项对照。

- `results/<tag>.log`：每轮完整工具日志。
- `results/<tag>.congestion-summary.rpt`：从完整日志原样摘出的最终全局布线拥塞表和线长。
- `results/<tag>.congestion.rpt`：工具在仍有拥塞时写出的逐区域报告；零拥塞轮可以不生成此文件，因此以始终生成的摘要为判定依据。
- `results/<tag>.drc.rpt`：详细布线 DRC 条目。
- 逐轮中间拥塞报告、guide 与 DEF 是复现产物，不作为入库结果。

所有数据来自手写教学夹具。资源调整系数用于在小设计上形成可观察的拥塞，不对应真实工艺折减；7 条 DRC 也明确表示调参轮尚未清零。这里的改善只说明本夹具在当前版本和固定随机种子下的变化，不等同于真实工艺签核，也不意味着密度越低越好。
