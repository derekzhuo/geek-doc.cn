# OpenSTA read_spef 报 instance not found（SPEF 层级名不匹配）

**对应教程**：https://geek-doc.cn/eda/ts-opensta-spef-read-fail.html（上线后生效）

## 复现方式

本地构建或拉取含 OpenSTA 2.0.17 的镜像 `geek-eda:0.3-sta` 后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `bad.tcl`：`top-bad.spef` 把连接引脚写成网表中不存在的实例 `u_bufx:A`，`read_spef` 报 `instance u_bufx:A not found`、`net u_bufx not found`，该网络的寄生标注被静默跳过；再跑 `good.tcl`：SPEF 连接改回网表真实层级 `u_buf2:A` 后读取零告警，`report_checks` 输出 slack 9.10 MET；最后 `net.tcl` 用 `report_net -connections n1` 核对驱动与负载引脚。
