# openlane-resume-from-tag

**对应教程**：https://geek-doc.cn/eda/ts-openlane-resume-from-tag.html

OpenLane 2023.07.19（sky130A，docker 镜像 efabless/openlane:d054702）复现 tag/续跑相关三类报错及正确用法。

## 复现

```bash
./run.sh
```

四个场景：

1. 旧的 `-from floorplan` 参数已移除：`-from and -to are no longer supported.`
2. 空 tag 直接跑后续步骤：openroad `Reading netlist '0' … cannot read file 0.`
3. 旧 tag 再次 prep 不加 `-overwrite`：`A run ... with tag 'r1' already exists.`
4. 正确：单个 `-interactive` 会话内按顺序 `run_synthesis` → `run_floorplan`。

## 目录

- `src/small_counter.v`：最小计数器设计；`configs/config.json`：基线配置。
- `run.sh`：四场景对照脚本（需要 OpenLane docker 环境与上层 olrun.sh / olrun-i.sh）。
