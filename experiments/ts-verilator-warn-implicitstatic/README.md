# Verilator IMPLICITSTATIC 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-implicitstatic.html

## 文件

- `implicitstatic_bad.sv`：模块内函数未写生命周期，局部变量带初始化器，触发 `IMPLICITSTATIC`。
- `implicitstatic_fixed.sv`：函数显式声明为 `automatic`，其余逻辑不变。
- `run.sh`：先确认报错版非零退出，再验证修复版零告警，最后输出 `PASS`。

## 复现

本机已安装 Verilator 5.020 时，在本目录运行：

```bash
bash run.sh
```

也可使用 Docker 镜像：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

报错版应出现 `%Warning-IMPLICITSTATIC` 和 `# bad_exit_code: 1`；修复版应出现 `# fixed_exit_code: 0` 与最终 `PASS`。
