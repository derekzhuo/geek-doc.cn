# OpenROAD ODB 数据库脚本化实验

**对应教程**：https://geek-doc.cn/eda/flow-openroad-odb-scripting.html（上线后生效）

这个最小工程演示 OpenROAD 26Q4 中的 Tcl 数据库操作：读取手写 LEF/DEF，遍历实例、网和顶层端口，分别用 `define_property/set_property/get_property` 与 OpenDB 字符串属性接口写入流程元数据，批量修改实例坐标与放置状态，写出 DEF 后在另一个 OpenROAD 进程中回读并逐项断言。连接保持通过逐网比较实例端子和顶层端口附件验证；另有空实例选择边界，确认零匹配会显式失败而不是静默通过。

## 运行

准备 `geek-eda:0.5-asic` 镜像，在本目录执行：

```bash
make run
```

也可以进入同一镜像后直接运行 `bash run.sh`。所有 OpenROAD 调用都带 `-no_init -exit`。

## 文件

- `fixtures/tech.lef`：一层金属和一个 CORE SITE。
- `fixtures/cells.lef`：一个 1×1µm 的 `BUF_X1`。
- `fixtures/input.def`：三个实例、四条网、两个顶层端口，距离单位为 1000 dbu/µm。
- `connectivity.tcl`：为每条网生成排序后的实例端子与顶层端口附件快照。
- `odb_roundtrip.tcl`：对象计数与遍历，批量执行 `set_property` 并读回，创建 OpenDB `audit_tag`，将三个实例横移 500 dbu 并设为 `FIRM`，比较修改前后的连接快照，写出 `results/roundtrip.def`。
- `verify_roundtrip.tcl`：新进程中回读 DEF，断言对象数、精确连接、坐标和状态；同时确认 `set_property` 元数据与通用 ODB 字符串属性均未被 DEF 序列化。
- `boundary.tcl`：查找不存在的 `u_missing`，对 `NULL` 结果显式报错。
- `run.sh`：串联主流程、独立回读、真实文件 diff 和边界检查。

成功时末尾出现 `ROUNDTRIP_RESULT PASS`、`DIFF_RESULT PASS`、`BOUNDARY_RESULT PASS` 和 `RUN_RESULT PASS`。`results/before-after.diff` 是输入与输出 DEF 的完整差异；格式化和显式 `USE SIGNAL` 是 DEF 写回时的规范化，三个实例的 `PLACED` 到 `FIXED` 以及横坐标增加 500 才是本实验主动修改的属性。

## 版本边界

实测版本为 `26Q4-1108-g6f3f28cc85`。`write_def` 的帮助只有版本与文件名参数，实测不会导出 `dbStringProperty_create` 创建的通用对象属性，也不会保留 `define_property/set_property` 写入的 `review_state`。需要跨文件交接的物理变更应写入 DEF 已定义的标准属性，例如实例位置和放置状态。其他元数据需要单独保存，不能假设一次 `write_def` 会保留整个数据库对象图。
