# Verilator DEFPARAM 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-defparam.html

## 文件

- `defparam_bad.sv`：实例化后使用 `defparam` 做层次参数覆盖，触发 `DEFPARAM`。
- `defparam_fixed.sv`：把相同的 `WIDTH=4` 移到实例化的 `#()` 中，以 `.WIDTH(4)` 具名传参。
- `width_adapter.sv`：参数化子模块，默认 `WIDTH=8`，两个顶层共用。
- `run.sh`：先确认报错版非零退出，再用同等 lint 选项验证修复版零告警。

## 复现

本机已安装 Verilator 5.020 时，在本目录运行：

```bash
bash run.sh
```

也可使用 Docker 镜像：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

报错版应出现 `%Warning-DEFPARAM` 和 `# bad_exit_code: 1`；修复版应出现 `# fixed_exit_code: 0` 与最终 `PASS`。
