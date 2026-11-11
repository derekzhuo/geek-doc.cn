# OpenSTA 调用 PrimeTime 方言命令报 invalid command name

**对应教程**：https://geek-doc.cn/eda/ts-opensta-tcl-command-unknown.html（上线后生效）

## 复现方式

本地构建或拉取含 OpenSTA 2.0.17 的镜像 `geek-eda:0.3-sta` 后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `bad.tcl`：把 PrimeTime 的 `report_qor` 命令直接带进 OpenSTA，报 `invalid command name "report_qor"`；再跑 `good.tcl`：改用 OpenSTA 等价命令 `report_clock_properties` 列出时钟属性，并正常 `report_checks` 输出时序路径。
