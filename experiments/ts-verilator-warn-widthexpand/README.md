# Verilator WIDTHEXPAND 零扩展与符号扩展对照

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-widthexpand.html（上线后生效）

这个最小实验比较隐式扩位与显式扩位。broken 同时包含 unsigned 和 signed 的 8 位到 16 位赋值；fixed 分别用零拼接和符号位复制写出扩展规则。

## 运行

本机安装 Verilator 5.x 时：

```bash
make run
```

使用教程同款容器时，在本目录执行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 make run
```

脚本要求 broken 非零退出并出现两条 `WIDTHEXPAND`，同时要求 fixed 无诊断且零退出；两项都满足才输出 `PASS`。`run1.log` 保存了 Verilator 5.020 的原始对照输出。
