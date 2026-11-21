# Yosys write_json 下游 QoR 统计

**对应教程**：https://geek-doc.cn/eda/flow-yosys-json-qor-script.html（上线后生效）

这个实验在同一 `proc; opt` 阶段导出三个结构不同的 RTLIL JSON：纯组合仲裁器、带异步复位的 8 位计数器、含一个子模块实例的寄存 ALU。Python 标准库脚本从顶层递归展开实例，统计叶单元，并把顶层直接单元计数与 `stat -json` 逐项对照。

## 运行

需要 Docker 和本机的 `geek-eda:0.4-flow` 镜像。镜像内有 Yosys 0.33 与 Python 3，统计脚本不依赖第三方 Python 包。

```bash
make run
# 等价于 bash run.sh
```

生成文件位于 `build/`：

- `<design>.json`：`write_json` 的完整 RTLIL 网表；
- `<design>.stat.json`：由 `tee -o ... stat -json` 保存的统计；
- `<design>.yosys.log`：Yosys 完整日志；
- `<design>.qor.log`：叶单元统计和直接计数对照结果。

## 统计口径

`direct_cells` 只数顶层 `modules[top].cells`，其中可能包含用户模块实例。`leaf_cells` 从顶层出发，凡 `cell.type` 是 `modules` 中的键就递归进入该模块，其余才计为叶单元。`direct_stat_match=PASS` 表示 Python 对顶层的直接计数与 Yosys `stat -json` 的 `num_cells_by_type` 完全一致；层次设计的叶单元结果另与 `stat` 的 `design hierarchy` 汇总核对。

这些数字只代表固定 Yosys 版本、固定 pass 阶段的单元对象数，不是门数、位数、面积或时序性能。修改优化命令、展平策略或技术映射后必须重新导出并比较。

## 可选图表

`scripts/plot_qor.py` 读取三个已生成的 JSON 并绘制组合/时序叶单元堆叠柱状图。该脚本需要 matplotlib：

```bash
python3 -m venv .venv
.venv/bin/pip install matplotlib
.venv/bin/python scripts/plot_qor.py --build build --output qor.svg
```
