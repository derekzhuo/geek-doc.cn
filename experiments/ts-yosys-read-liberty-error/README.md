# Yosys read_liberty 解析报错最小复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-read-liberty-error.html（上线后生效）

`bad.lib` 在输入引脚的 `direction` 后故意省略冒号；`good.lib` 只补回这个冒号。运行脚本先确认坏例被 `read_liberty` 拒绝，再让合法库经过 `read_liberty -lib` 和 `abc -liberty`，把 `top.v` 中的一位反相器映射到 `INV_X1`。

## 复现

准备 Docker 镜像 `geek-eda:0.2`，在本目录执行：

```bash
bash run.sh
```

预期坏例非零退出，合法例退出码为 0，末尾出现 `PASS bad input rejected; good library loaded and mapped`。实验库只含解析和映射所需字段，不用于报告真实工艺的面积或时序。
