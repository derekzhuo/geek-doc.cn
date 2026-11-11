# ngspice model 卡缺失（could not find a valid modelname）

**对应教程**：https://geek-doc.cn/eda/ts-ngspice-model-card-missing.html（上线后生效）

## 复现方式

本机安装 ngspice（macOS 实测版本 ngspice-47）后，在本目录执行：

```bash
bash run.sh
```

脚本先跑 `inverter_bad.cir`：两个 MOS 管引用了 `nmos`/`pmos` 模型名却没有任何 `.model` 定义，ngspice 先警告 `can't find model`，随后报 `could not find a valid modelname` 并以退出码 1 中断；再跑 `inverter_fixed.cir`：补回 level=1 的两张模型卡并做 `.dc` 扫描，打印出完整的反相器传输曲线（输入 0–1.8 V 对应输出 1.8 V–0 V），退出码 0。
