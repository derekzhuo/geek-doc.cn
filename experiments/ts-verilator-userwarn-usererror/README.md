# Verilator USERWARN 与 USERERROR 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-userwarn-usererror.html（上线后生效）

- `userwarn_bad.sv`：非法深度触发 elaboration 阶段的 `$warning`。
- `usererror_bad.sv`：非法位宽触发 elaboration 阶段的 `$error`。
- `params_fixed.sv`：合法参数通过 lint，同时保留参数守卫。
- `run.sh`：依次复现两类诊断、验证修复，并确认修复版仍能拒绝非法覆盖参数。

在安装了 Verilator 5.020 的 Linux 环境运行：

```bash
bash run.sh
```

也可从公开仓库根目录使用同一镜像复现：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash experiments/ts-verilator-userwarn-usererror/run.sh
```
