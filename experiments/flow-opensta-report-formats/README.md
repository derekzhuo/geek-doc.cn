# flow-opensta-report-formats

**对应教程**：https://geek-doc.cn/eda/flow-opensta-report-formats.html

OpenSTA 2.0.17 `report_checks` 报告导出格式与 grep/awk 后处理的最小可复现实例。

## 内容

- `teaching.lib`：教学用最小 liberty（1 个 DFF_P + 1 个 BUF_X1，标量延时），复用自 experiments/flow-opensta-report-checks-reading，不对应任何真实工艺，产线需替换为 PDK 签核库。
- `top.v`：四条并行 DFF 路径，BUF 级数 1/2/3/4，配合 0.8ns 时钟制造 -0.10/-0.40/-0.70 三档 setup 违例。
- `export.tcl`：用 tcl 重定向把 short/end/full/full_clock/summary 五种 `-format` 与 `-slack_max 0` 筛选分别导出到 `reports/`。
- `run.sh`：容器内全流程，含 help report_checks 真机片段与 grep/awk 后处理演示。

## 复现

```bash
make run
# 或本机已装 OpenSTA：
STA_BIN=sta bash run.sh
```
