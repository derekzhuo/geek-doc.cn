# OpenSTA link 找不到 cell 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-opensta-link-missing-cell.html （上线后生效）

本实验用同一份 Liberty 和两份只差一个 cell 名的网表，对照严格链接时的未定义 cell、未读 Liberty 与修复后的 `report_checks`。故障脚本设置 `set link_make_black_boxes 0`，避免链接器把缺失定义静默改成黑盒。

## 文件

- `experiment.lib`：只含 `DFFX1` 与 `BUFX1` 的教学时序库，不对应真实工艺。
- `missing_cell.v`：故意实例化未定义的 `MISSING_BUF`。
- `fixed.v`：把输出缓冲改回库中已有的 `BUFX1`。
- `missing_cell.tcl`：读取库和故障网表后执行严格 `link_design`。
- `no_library.tcl`：故意不读 Liberty，观察两个库 cell 都无法解析。
- `fixed.tcl`：链接修复网表，添加时钟与 I/O 延迟并执行 `report_checks`。
- `run.sh`：运行三组对照并记录各组退出码。

## 复现

安装 OpenSTA 后，在本目录执行：

```bash
bash run.sh
```

默认把记录写入本目录的 `run1.log`。如需指定位置：

```bash
LOG_PATH=/tmp/opensta-link-missing-cell.log bash run.sh
```

本次记录使用 OpenSTA 2.0.17、Ubuntu 24.04 容器。两组故障均输出 `module ... not found`，修复组输出 `slack (MET)`。该版本即使 Tcl 脚本出现链接错误，三组进程退出码仍均为 0，因此必须检查日志，不能只依赖退出码。
