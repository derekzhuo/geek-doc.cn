# ngspice measure 引用不存在的向量（no such vector）

**对应教程**：https://geek-doc.cn/eda/ts-ngspice-vector-undefined-plot.html（上线后生效）

## 复现方式

本机安装 ngspice（macOS 实测版本 ngspice-47）后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `meas_bad.cir`：`.measure` 语句引用了网表里根本不存在的节点 `v(outx)`，ngspice 报 `Error: measure tcross when(WHEN) : no such vector as 'v(outx)'` 并以退出码 1 中断；再跑 `meas_fixed.cir`：把引用改成真实节点 `v(out)` 后测量正常完成，打印出 `tcross` 测量值，退出码 0。
