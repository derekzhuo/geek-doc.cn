# Verilator UNOPTTHREADS 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-unoptthreads.html（上线后生效）

四个独立计数器用于观察 Verilator 5.020 的线程分区行为。`--threads-max-mtasks 2` 把小型示例的分区上限压低，使调度器在请求两个线程时稳定进入 UNOPTTHREADS；这不是建议给正常工程设置的值。

运行环境：Docker 镜像 `geek-eda:0.2`。

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本依次验证：受限分区出现预期告警；改用单线程后通过；保留双线程并放宽 MTask 上限后通过；只增加模块层级但仍限制 MTask 数量时告警仍在。脚本在所有结果符合预期时返回 0。

- `top.sv`：四个计数过程写在同一模块。
- `counter.sv`、`hierarchical.sv`：相同逻辑的层级化版本。
- `run.sh`：完整复现与结果检查。
