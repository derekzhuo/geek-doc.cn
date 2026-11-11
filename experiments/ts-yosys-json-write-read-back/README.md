# Yosys JSON 网表回读实验

**对应教程**：https://geek-doc.cn/eda/ts-yosys-json-write-read-back.html

这个样例在 Yosys 0.33 中执行 `write_json → read_json → write_verilog`，并检查参数化位宽、复位常量、属性和层次字段。`stat` 与 `check` 用于观察回读后的当前样例，不构成通用形式等价证明。

## 运行

```bash
bash run.sh
```

脚本需要 Docker 镜像 `geek-eda:0.2`，会生成 `roundtrip.json` 与 `roundtrip_out.v`。输入在 `roundtrip.v`，Yosys 命令序列在 `roundtrip.ys`。
