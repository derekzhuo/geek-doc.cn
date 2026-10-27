# ts-yosys-abc-fail-missing-cell-library

复现 Yosys `abc:ERROR: Unable to open liberty file` / 单元映射失败。

## 复现

```bash
bash run.sh
```

- `logs/err-bad-libdir.log`：`abc -liberty` 指向不存在的路径，abc 找不到单元库。
- `logs/fix-real-liberty.log`：探测本机 sky130A PDK 的
  `sky130_fd_sc_hd__tt_025C_1v80.lib` 后映射通过；未装 PDK 时该文件写明跳过原因。

根因：abc 做工艺相关映射必须给真实 liberty；generic 综合阶段不需要库，
一到 `abc`/`dfflibmap`/`abc -liberty` 就必须保证路径、权限、文件格式三者都对。

## 环境

Yosys ≥ 0.9；修复项另需 sky130A PDK（volare 或 open_pdks）。

## 原始证据

本目录 `evidence/`（原始日志，与教程内嵌摘录同源）
