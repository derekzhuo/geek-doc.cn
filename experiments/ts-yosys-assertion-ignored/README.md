# Yosys 普通读取与 formal 模式下的断言对照

**对应教程**：https://geek-doc.cn/eda/ts-yosys-assertion-ignored.html（上线后生效）

本目录包含 immediate assertion、简单 concurrent assertion，以及带时钟与蕴含符的 concurrent 写法。`run.sh` 使用 Docker 镜像 `geek-eda:0.2` 中的 Yosys 0.33，分别比较 `read_verilog -sv`、`read_verilog -sv -noassert` 和 `read_verilog -sv -formal`，再执行 `hierarchy -check`、`proc`、`check` 与 `stat`。脚本还检查复杂 concurrent 写法在普通与 formal 模式下都按预期报语法错误。

## 复现

```bash
cd experiments/ts-yosys-assertion-ignored
bash run.sh
```

运行环境需要 Docker，并能访问本地 `geek-eda:0.2` 镜像。脚本只比较前端读取和 RTLIL 转换结果，不运行仿真、不调用 SMT 求解器，也不代表任何属性已经通过形式证明。
