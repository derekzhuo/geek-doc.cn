# ngspice 瞬态仿真不收敛（Transient op failed, timestep too small）

**对应教程**：https://geek-doc.cn/eda/ts-ngspice-convergence-timestep-fail.html（上线后生效）

## 复现方式

本机安装 ngspice（macOS 实测版本 ngspice-47）后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `bad.cir`：两个理想电压源直接并联构成零电阻环，节点矩阵奇异，ngspice 依次打印 `singular matrix`、`Dynamic gmin stepping failed`、`True gmin stepping failed`、`source stepping failed`，最终报 `Transient op failed, timestep too small` 并以退出码 1 中断。随后给出两条修复路径对照：`fixed_remove.cir` 删掉冲突电压源只保留一个；`fixed_resistor.cir` 串入 `Rs 1 2 100` 让方程重新有唯一解，两者均退出码 0。
