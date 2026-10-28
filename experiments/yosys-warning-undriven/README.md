# yosys-warning-undriven

**对应教程**：https://geek-doc.cn/eda/ts-yosys-warning-undriven.html

复现 Yosys `check` pass 报的 `Warning: Wire <module>.\<signal> [n] is used but has no driver.` 警告（信号声明了但没有任何驱动源），以及修复后的复跑确认。

## 文件

- `undriven_bad.v`：坏设计。`data_sync` 声明后被下游 `assign` 消费，但没有任何驱动源（重构时删掉了同步寄存器的残留）。
- `undriven_fixed.v`：修复版。把同步寄存器补回来，`data_sync` 有明确驱动。

## 复现

环境：Yosys 0.33（教程中使用 `geek-eda:0.2` docker 镜像；本机装有 Yosys 也可直接跑）。

```bash
# 坏设计：8 条 undriven 警告
yosys -p 'read_verilog undriven_bad.v; hierarchy -top undriven_bad; proc; check'

# 坏设计走完 synth：逻辑被常量折叠吃光，Number of cells = 0
yosys -p 'read_verilog undriven_bad.v; hierarchy -top undriven_bad; synth; stat'

# 修复版复跑：Found and reported 0 problems
yosys -p 'read_verilog undriven_fixed.v; hierarchy -top undriven_fixed; proc; check'
```

docker 复现（在宿主机该目录下）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 \
  yosys -p 'read_verilog undriven_bad.v; hierarchy -top undriven_bad; proc; check'
```
