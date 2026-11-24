# OpenROAD initialize_floorplan 报 IFP-0002（core 面积放不下实例）

**对应教程**：https://geek-doc.cn/eda/ts-openroad-floorplan-init-fail.html（上线后生效）

## 复现方式

本地构建或拉取含 OpenROAD 26Q4 的镜像 `geek-eda:0.5-asic` 后，在本目录执行：

```bash
bash run.sh
```

三档对照（同一个 `top.v`，内含一个 0.68µm×1.0µm 的 `invx1` 实例 `u_inv`）：

1. `bad.tcl`：die/core 都给 0.5µm×0.5µm，`initialize_floorplan` 报 `[ERROR IFP-0002] u_inv (0.680um, 1.000um) does not fit in the core area`，退出码 1。
2. `mid.tcl`：core 放大到 1.0µm×1.0µm，行高/站点网格对齐后实际 core 0.680µm×1.000µm、面积 0.680µm²，与实例面积恰好相等，`Effective utilization: 1.000` 仍通过——IFP-0002 的判据是实例放不放得进 core 尺寸，不是利用率不得达到 100%。
3. `good.tcl`：core 20µm×20µm，core 面积 394.400µm²、利用率 0.002，`report_design_area` 正常输出。

LEF 与宏定义复用同仓 `ts-openroad-lef-layer-not-found` 的最小 tech/macro LEF；日志中的 `[WARNING ORD-2011] LEF master invx1 has no liberty cell` 是纯 LEF 流程的正常提示，floorplan 只需 LEF 主尺寸，不需要时序库。

## 文件

| 文件 | 作用 |
|---|---|
| `top.v` | 单实例顶层：一个 invx1 |
| `tech.lef` / `macro.lef` | 最小工艺/宏 LEF（metal1/via1 + unit SITE + invx1） |
| `bad.tcl` / `mid.tcl` / `good.tcl` | 0.5 / 1.0 / 20µm 三档 core |
| `run.sh` | 三档串联复现 |
