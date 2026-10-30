# Verilator ASCRANGE 升序位选最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-ascrange.html（教程上线后生效）

本目录用一个四位输入端口复现 `[0:3]` 升序位选声明触发的 `ASCRANGE`，再把声明统一为 `[3:0]`，保持拼接表达式不变并复跑 lint。Verilator 5.020 使用 `ASCRANGE`；旧资料中的 `LITENDIAN` 是兼容别名。

## 文件

- `ascrange_bad.sv`：反例，输入声明为 `[0:3]`。
- `ascrange_fixed.sv`：修复版，输入声明为 `[3:0]`，拼接逻辑不变。
- `run.sh`：检查反例确实输出 `ASCRANGE`，随后验证修复版通过并打印退出码和 `PASS`。

## 复现

在安装 Verilator 5.020 的 Linux 环境中执行：

```bash
bash run.sh
```

也可使用本教程的 Docker 镜像，在仓库根目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 \
  bash experiments/ts-verilator-warn-ascrange/run.sh
```

反例的非零退出是预期现象；脚本只有同时观察到 `ASCRANGE` 和修复版 `PASS` 才以零状态退出。
