# Magic 找不到 tech 文件：minimum 静默回退与零 DRC 规则

**对应教程**：https://geek-doc.cn/eda/ts-magic-drc-tech-file-missing.html（上线后生效）

## 复现方式

准备包含 Magic 8.3 revision 105 的本地 Docker 镜像 `geek-eda:0.5-asic`，在本目录执行：

```bash
bash run.sh
```

两档运行都把同一个 `probe.tcl` 交给 `magic -noconsole -dnull`，探针只查询实际工艺名、DRC 风格与规则数据库统计，不修改任何版图：

```tcl
puts "PROBE tech=[tech name]"
drc style
drc rulestats
quit -noprompt
```

1. 错误档使用 `-T definitely_missing`。Magic 两次打印 `Could not find file` 与 `Failed to load technology`，随后不是退出，而是打印 `Using technology "minimum", version 0.0`。`PROBE tech=minimum`，`Total number of rules specified in tech file: 0`，最终退出码仍为 0。
2. 修复档改用镜像内置的 `-T scmos`。实际工艺为 `scmos`、版本 8.2.8，tech 文件规则总数为 155，优化后边规则数据库保留 13742 条，退出码也是 0。

因此不能用进程退出码判断工艺是否加载成功。至少要同时检查 `tech name` 是否符合预期、`Failed to load technology` 是否出现，以及 `drc rulestats` 的规则数是否符合所用工艺。`scmos` 只是本镜像中用于验证有效加载的内置工艺，不是对真实项目 PDK 的替换建议。

## 文件

| 文件 | 作用 |
|---|---|
| `probe.tcl` | 查询实际 tech 名称、DRC 风格与规则统计 |
| `run.sh` | 串联错误 tech 与内置 scmos 两档，分别打印退出码 |
