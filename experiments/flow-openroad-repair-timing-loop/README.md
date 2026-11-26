# flow-openroad-repair-timing-loop

**对应教程**：https://geek-doc.cn/eda/flow-openroad-repair-timing-loop.html（上线后生效）

OpenROAD 时序修复闭环实验：在没有任何工艺 PDK 的条件下，用手写的最小 tech LEF、标准单元 LEF（BUF_X1/BUF_X2）与带 3x3 时序弧的教学 Liberty，构造一个高扇出欠优设计（1 个源缓冲驱动 40 个负载，外加一条短保持路径），跑通「全局布局 → 连线 RC 估计 → 虚拟时钟约束 → repair_design setup 迭代 → repair_timing -hold」的完整闭环，并留下每一轮的 WNS/TNS 数字与实例数变化。

## 重要边界

- 全部夹具为手写教学件：三层金属、轨道间距 0.28um、数据库单位 2000/um、300×300um die；连线 RC 由 `set_wire_rc` 给教学值，不代表任何真实工艺，数字只用于演示修复闭环与命令语义。
- 实验基于 OpenROAD 26Q4（`openroad -version` 输出 `26Q4-1108-g6f3f28cc85`）。该版本 rsz 只认 Liberty 中以 `pg_pin(...) { pg_type : primary_power/primary_ground }` 声明电源脚的缓冲单元；普通 `pin(VDD) { direction : inout }` 写法会让单元的 buffer 推断失效，repair_design 报 RSZ-0022「no buffers found」。
- 组合路径用虚拟时钟加 input/output delay 约束，无需真实时钟树综合即可演示 setup/hold 修复；外部保持时间用负的 min output delay 建模。

## 文件

- `fixtures/tech.lef`：最小 tech LEF（SITE、三层金属、制造网格）。
- `fixtures/stdcell.lef`：BUF_X1（1×1um）与 BUF_X2（2×1um）两个缓冲单元。
- `fixtures/teaching.lib`：教学 Liberty，3x3 查找表时序弧，`is_buffer : true` 加 `pg_pin` 电源脚。
- `fixtures/top.v`：高扇出网表，u_root 驱动 40 个负载缓冲，另有 d_short→u_short→z_short 短路径。
- `scripts/01_baseline.tcl`：布局、寄生估计、SDC 约束与修复前基线 WNS/TNS，写出 `01_baseline.def`。
- `scripts/02_setup_repair.tcl`：接续基线 DEF，两轮 `repair_design -max_wire_length 20`，每轮重估寄生并记录 SLAP 行与单元直方图。
- `scripts/03_hold_repair.tcl`：接续 setup 修复 DEF，`repair_timing -hold` 插入保持缓冲并复核 setup 不回退。
- `run.sh`：依次执行三个阶段，校验最终 setup/hold WNS 同时转正、TNS 归零并输出 `RUN_RESULT EXPECT_MATCH`。

## 复现

```bash
make run
# 等价于
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

各阶段日志与写出的 DEF 落在 `results/`（运行生成物，不入库）。
