# OpenROAD SAIF 功耗分析实验

**对应教程**：https://geek-doc.cn/eda/flow-openroad-power-report.html（上线后生效）

这个最小工程把 90ns 门级仿真活动转换为 SAIF，在 OpenROAD 26Q4 中通过 `read_saif -scope tb/dut` 反标，再用 `report_power` 分解内部、开关和漏电功耗。另一个进程用 `set_power_activity -input -activity 0.1 -duty 0.5` 给出无向量对照；两个边界用例分别检查错误层次和额外未映射网名。

## 准备镜像并运行

`geek-eda:0.5-asic` 是本实验使用的本地镜像标签，不是可从镜像仓库直接拉取的名称。新机器可在本目录从公开源码构建同标签镜像：

```bash
make image
make run
```

`make image` 以 Ubuntu 24.04 为基底，从官方 OpenROAD 仓库检出提交 `6f3f28cc85`，运行上游依赖安装和构建脚本，再安装 Ubuntu 的 Icarus Verilog 12.0 与 Python 3.12.3。构建需要访问 Ubuntu 软件源和 GitHub，编译时间取决于机器；末尾会断言三个工具的精确版本。已有同版本镜像时只需执行 `make run`。

也可以执行 `docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'`，或进入同一镜像后直接运行 `bash run.sh`。脚本会重跑 Icarus 仿真、VCD 到 SAIF 转换、两种功耗场景和两个边界，并检查关键标注计数与总功耗。成功时末尾出现 `RUN_RESULT PASS`。

## 文件

- `Dockerfile`、`Makefile`：从官方固定提交构建所需镜像，并提供 `make image`、`make run` 两个入口。
- `fixtures/teaching.lib`：教学 Liberty，时间单位 1ns、电容单位 1pF、漏电单位 1nW；含 `AND2_X1` 与 `XOR2_X1` 的时序、内部功耗和漏电模型。
- `fixtures/tech.lef`、`fixtures/cells.lef`：满足 OpenROAD `link_design` 技术库要求的最小 LEF。
- `fixtures/top.v`：`u_and` 驱动 `u_xor` 的两单元门级设计。
- `tb/tb.v`、`tb/cells.v`：90ns 激励和对应功能模型，产生 `results/activity.vcd`。
- `scripts/vcd_to_saif.py`：把指定 scope 的直接子级标量 0/1 信号转换成 SAIF，保留 T0、T1、TC 和仿真时长。
- `power_saif.tcl`：读取 `tb/dut` 活动并报告设计总量及两个实例的功耗。
- `power_vectorless.tcl`：设置 10ns 时钟和输入活动率 0.1，给出无向量对照。
- `power_missing_scope.tcl`：读取不存在的 `tb/missing_dut`。
- `power_unmapped.tcl`：读取额外含 `ghost` 网名的 SAIF。
- `run.sh`：完整命令序列和结果断言。

## 实测结果与边界

实测版本为 OpenROAD `26Q4-1108-g6f3f28cc85`、Icarus Verilog 12.0、Python 3.12.3。正确 scope 标注 5 个引脚活动，总功耗为 `9.763717799e-07 W`；无向量对照为 `4.328659884e-07 W`。错误 scope 打印 `Annotated 0 pin activities.` 后仍返回状态码 0，报告回落到默认活动；额外 `ghost` 不改变 5 个引脚的标注计数。因此脚本把标注计数作为独立验收项，而不只看进程是否成功。

OpenSTA 接受的 SAIF 结构是一个 `NET` 组内包含多个 `(网名 (T0 ...) (T1 ...) (TC ...))` 记录。随附转换器只覆盖本实验需要的直接子级标量 0/1 信号，不处理 X/Z、总线、条件活动和任意层次，不能当作通用格式转换器。

所有功耗数值只用于验证这条命令链。教学库不是工艺 PDK，没有 SPEF、输出负载、毛刺统计或多角多模式约束，结果不能用于绝对功耗或签核判断。
