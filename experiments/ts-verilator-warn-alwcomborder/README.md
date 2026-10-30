# Verilator ALWCOMBORDER 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-alwcomborder.html（上线后生效）

本目录给出 `always_comb` 中先读后写触发 `ALWCOMBORDER` 的最小源码，以及调整赋值顺序后的修复版。

## 文件

- `alwcomborder_bad.sv`：先读 `tmp`、后写 `tmp`，预期 lint 失败。
- `alwcomborder_fixed.sv`：先计算 `tmp`、再读取，预期 lint 通过。
- `run.sh`：依次运行错误版与修复版，并检查两者的退出状态。

## 复现

已安装 Verilator 5.020 时：

```bash
chmod +x run.sh
./run.sh
```

使用 Docker 镜像时：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash ./run.sh
```

预期错误版出现 `%Warning-ALWCOMBORDER`，修复版输出 `PASS: fixed source passed lint with no warnings`。
