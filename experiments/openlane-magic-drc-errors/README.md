# openlane-magic-drc-errors：Magic 独立 DRC 间距违例复现

**对应教程**：<https://geek-doc.cn/eda/ts-openlane-magic-drc-errors.html>

## 环境

- Magic 8.3 rev413（OpenLANE d054702b 容器内）/ sky130A tech 1.0.424
- 日期：2026-11-06；原始输出见 `bad-magic-drc.log`、`good-magic-drc.log`

## 复现

```bash
PDKR=$HOME/.volare ./run.sh
```

- `tcl/drc-bad.tcl`：两条 0.5um 宽 met1 矩形间距仅 0.03um，full DRC 风格下报 `Metal1 spacing < 0.14um (met1.2)`，共 2 个 rule hits。
- `tcl/drc-good.tcl`：同结构把间距放宽到 0.20um（大于 0.14um 阈值），`drc listall why` 返回空，0 违例。

关键姿势：脚本内先 `drc euclidean on` + `drc style drc(full)` 再 `drc catchup`，否则默认风格下部分 sky130A 规则不参与检查；层名必须用 PDK 名 `met1`（不是 `metal1`）。

## 文件

- `tcl/drc-bad.tcl` / `tcl/drc-good.tcl`：违例 / 干净两组 Magic Tcl 版图脚本。
- `run.sh`：在 OpenLANE 容器内连跑两轮的对照脚本。
- `bad-magic-drc.log` / `good-magic-drc.log`：两轮真机日志（含三行头与 rule hits 统计）。
