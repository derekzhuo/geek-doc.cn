# openlane-pl-target-density

**对应教程**：https://geek-doc.cn/eda/ts-openlane-pl-target-density.html

OpenLane 2023.07.19 / OpenROAD：复现 `PL_TARGET_DENSITY` 超出 0~1 范围导致全局布局失败。

## 复现

```bash
./run.sh
```

- CASE A：`PL_TARGET_DENSITY=1.5`，STEP 7 报 `[ERROR GPL-0135] Target density must be in [0, 1].`
- CASE B：改回 0.5，synthesis→floorplan→placement 全部通过。

## 目录

- `src/small_counter.v`：最小计数器设计。
- `configs/config.base.json`：合法基线配置（脚本把 density 改成 1.5 制造 CASE A）。
- `run.sh`：对照脚本（需要 OpenLane docker 环境与上层 olrun.sh / olrun-i.sh）。
