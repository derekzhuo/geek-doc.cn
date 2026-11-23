# flow-openroad-macro-placement

**对应教程**：https://geek-doc.cn/eda/flow-openroad-macro-placement.html（上线后生效）

OpenROAD 宏单元摆放实验：在没有任何工艺 PDK 的条件下，用手写的最小 tech LEF、两个宏单元 LEF（SRAM64/SRAM40）、教学 Liberty 与 DEF/Verilog 网表，跑通 floorplan 阶段的宏摆放全流程，并用摆放前后的 DEF 坐标对照、`set_halo` 前后的 global placement 避让计数，量化 halo 与宏周边通道的关系。

## 重要边界

- 全部夹具为手写教学件：金属层只有三层、轨道间距 0.28um、数据库单位 2000/um，不代表任何真实工艺，数字只用于演示工具行为与命令语义。
- 实验基于 OpenROAD 26Q4（`openroad -version` 输出 `26Q4-1108-g6f3f28cc85`）。该版本没有旧教程里的 `place_cell` 命令，手动摆放用 `place_macro -exact` 或 `place_inst`，halo 用独立的 `set_halo` 命令设置；其 LEF 解析器不接受 LEF `TRACKS` 语句，轨道网格由 `make_tracks` 在 Tcl 侧建立。

## 文件

- `fixtures/tech.lef`：最小 tech LEF（SITE、三层金属、制造网格）。
- `fixtures/sram64.lef` / `fixtures/sram40.lef`：两个块状宏单元，尺寸 60×60um 与 40×60um。
- `fixtures/stdcell.lef`：1×1um 的教学标准单元 BUF_X1，供 global placement 对照实验使用。
- `fixtures/teaching.lib`：最小教学 Liberty。
- `fixtures/design_unplaced.def`：200×200um die，两个 UNPLACED 宏实例。
- `fixtures/top.v` / `fixtures/top_gp.v`：两份网表，后者含 48 级 BUF 链。
- `scripts/01_def_macro_place.tcl`：DEF 驱动流程，摆放前后坐标、软阻挡、halo 与两份 DEF 对照。
- `scripts/02_floorplan_init.tcl`：网表驱动流程，`initialize_floorplan` 自动建 die area 与 row。
- `scripts/03_gp_halo_compare.tcl`：halo 避让对照（模式由环境变量 `GP_MODE=nohalo|halo` 选择）。
- `run.sh`：依次执行三个流程，解析 `GP_RESULT` 行并校验「加 halo 后进入避让带的单元数必须下降、宏本体内必须为 0」。

## 复现

```bash
make run
# 等价于
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

各阶段日志与写出的 DEF 落在 `results/`（运行生成物，不入库）。
