# Verilator GENUNNAMED 未命名 generate 复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-genunnamed.html （上线后生效）

`unnamed.sv` 用未命名的条件 `generate` 块触发 `GENUNNAMED`，`named.sv` 只给块增加 `g_select` 标签，其余组合逻辑不变。`run.sh` 验证前者按预期失败、后者通过 `-Wall`  lint。

## 运行

需要 Docker 与本地 `geek-eda:0.2` 镜像（Verilator 5.020）。在本目录的上一级 experiments 目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work/ts-verilator-warn-genunnamed geek-eda:0.2 bash run.sh
```

也可以直接进入本目录，把挂载路径改为本目录并将工作目录设为 `/work`。脚本只运行 lint，不生成 C++ 模型或构建产物。
