# openlane-pdk-version-mismatch

**对应教程**：https://geek-doc.cn/eda/ts-openlane-pdk-version-mismatch.html

OpenLane 2023.07.19（docker efabless/openlane:d054702，PDK 由 volare 管理）复现
PDK 名字写错、PDK_ROOT 指错目录两类报错。

## 复现

```bash
./run.sh
```

- PDK=sky130C（未安装）：`Failed to compare PDKs. ~/.volare/sky130C not found.`
- PDK_ROOT 指向空目录：`/wrongpdk/sky130A not found.`
- 改回已安装的 sky130A 后 synthesis 通过。

## 目录

- `src/small_counter.v`：最小计数器设计；`configs/config.json`：基线配置。
- `run.sh`：三种场景对照（需要本机装有 OpenLane docker 镜像与 volare sky130A）。
