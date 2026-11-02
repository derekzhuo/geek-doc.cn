# flow-yosys-write-netlist

**对应教程**：https://geek-doc.cn/eda/flow-yosys-write-netlist.html

同一份 RTL（带使能与异步复位的 4 位计数器 `counter4.v`）经 Yosys 0.33 综合后，用三种后端导出网表的最小实验：

- `write_verilog netlist_default.v`：默认门级 Verilog（内部单元折成表达式，保留属性）
- `write_verilog -noattr -noexpr -nodec netlist_clean.v`：逐门实例化、去属性、常量按位写的交付版网表
- `write_json design.json`：modules/cells/netnames/ports 结构化网表
- `write_blif design.blif`：BLIF 交换格式（`.names` 真值表 + `.subckt` 触发器）

## 复现

需要本机装有 Docker 与镜像 `geek-eda:0.3-sta`（内含 Yosys 0.33）：

```bash
make run      # 容器内执行 yosys -s run.ys，生成四个产物
make check    # 对照文件大小与 13 个 cell 实例数
make clean    # 删除生成文件
```

`ref-output/` 留存本次实测的四个产物样本（共约 13 KB），供无 Docker 环境直接对照阅读；重新 `make run` 会在工程根目录再生成一份。

## 实测环境

- Yosys 0.33（git sha1 2584903a060），geek-eda:0.3-sta 容器
- 日期：2026-11-03
- 终态统计：13 个 cell（`$_DFFE_PN0P_` x4、`$_ANDNOT_` x2、`$_NAND_` x2、`$_NOT_`/`$_OR_`/`$_XNOR_`/`$_XOR_` 各一）
