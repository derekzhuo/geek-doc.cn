# OpenROAD read_lef 报 undefined layer（LEF 加载顺序颠倒）

**对应教程**：https://geek-doc.cn/eda/ts-openroad-lef-layer-not-found.html（上线后生效）

## 复现方式

本地构建或拉取含 OpenROAD 26Q4 的镜像 `geek-eda:0.5-asic` 后，在本目录执行：

```bash
bash run.sh
```

实验分四步：

1. `bad.tcl` 先读 `macro.lef`：此时 `metal1` 与 `unit` 尚未由 tech LEF 定义，OpenROAD 打出两条 `[WARNING ODB-0176] error: undefined layer (metal1) referenced` 与一条 `[WARNING ODB-0186] macro invx1 references unknown site unit`，但仍 `created 1 library cells`、退出码 0——宏单元被接受，PIN 几何被静默剥除。
2. `good.tcl` 先 `tech.lef` 再 `macro.lef`：`created 2 layers` 后 `created 1 library cells`，全程零告警。
3. `probe-bad.tcl` 回写 `roundtrip-bad.lef`：`write_lef` 吐出的宏单元只剩 PIN 方向，PORT/RECT 几何行数为 0，SITE 引用也丢失。
4. `probe-good.tcl` 回写：库 LEF 自动写到 `_1` 后缀文件，`roundtrip-good_1.lef` 保留完整 PORT/RECT（几何行数 2）与 SITE。

脚本末尾自动清理回写产物。

## 文件

| 文件 | 作用 |
|---|---|
| `tech.lef` | 最小工艺 LEF：metal1/via1 两层 + unit SITE |
| `macro.lef` | 最小宏 LEF：invx1，两个 PIN 各带一段 metal1 矩形 |
| `bad.tcl` / `good.tcl` | 颠倒 / 正确加载顺序 |
| `probe-bad.tcl` / `probe-good.tcl` | 回写探针，量化静默丢几何的后果 |
| `run.sh` | 四步串联复现，自动清理产物 |

## 注意

OpenROAD 26Q4 对未定义层/未知 SITE 只打 ODB-0176/ODB-0186 警告并继续，不保证更早或其他构建版本行为相同；语法错误（LEFPARS 族）才是硬失败且丢弃整份 LEF。排查时用 `grep -E 'RECT[[:space:]]'` 之类精确模式数几何，`grep RECT` 会误命中 `DIRECTION`。
