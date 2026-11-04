# tpl-openlane-config-json

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-openlane-config-json.html

OpenLane 2023.07.19 / sky130A 最小 config.json 模板的可跑参考工程（RTL → GDS 完整 flow）。

## 复现

```bash
# 需要 OpenLane docker 环境（efabless/openlane:d054702）与 volare sky130A PDK
# run.sh 内的 docker -v 挂载参数按本机路径调整
./run.sh
```

实测（2C7.4G 云主机）：42 步全过，synthesis 62 cells、芯片面积 609.33 um^2，
Magic DRC 0、LVS clean、天线 0 违例。

## 目录

- `src/small_counter.v`：12 位同步使能计数器（约 62 门）。
- `config.json`：最小关键字段模板（每项都被成功 run 验证过）。
- `run.sh`：完整 flow 包装脚本。
