# ngspice 找不到 subcircuit 定义（unknown subckt）

**对应教程**：https://geek-doc.cn/eda/ts-ngspice-subckt-not-found.html（上线后生效）

## 复现方式

本机安装 ngspice（macOS 实测版本 ngspice-47）后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `bad.cir`：X 实例引用了 `amp` 子电路却没有任何 `.subckt`/`.include` 定义，ngspice 报 `Error: unknown subckt` 并以退出码 1 中断；再跑 `fixed.cir`：通过 `.include amp.cir` 补上子电路定义后 `.op` 工作点分析正常完成，退出码 0。
