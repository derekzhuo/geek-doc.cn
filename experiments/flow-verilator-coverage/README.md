# Verilator 覆盖率收集流程实验（行/分支/翻转覆盖）

**对应教程**：https://geek-doc.cn/eda/flow-verilator-coverage.html

同一个 4 位可加载计数器 `counter.v`，两版 C++ harness 演示 Verilator 5.020 的覆盖率采集与合并：

- `tb_partial.cpp`：只复位 + 使能计数，从不拉 `load`
- `tb_full.cpp`：补上 `load` 加载场景（加载值 0xA）

## 复现

需要本机有 Docker 与 `geek-eda:0.3-sta` 镜像（Verilator 5.020 + verilator_coverage）：

```bash
make run        # 等价于 docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash run.sh
```

产物（均不入库）：

- `obj_dir/Vcounter` / `obj_dir_full/Vcounter`：两版插桩仿真可执行文件
- `partial.dat` / `full.dat`：两版 harness 各自的覆盖率数据
- `merged.dat`：`verilator_coverage --write` 合并后的覆盖率数据
- `logs_partial/` / `logs_full/` / `logs_merged/`：`--annotate` 生成的逐行命中注释源码，`%000000` 表示零命中

清理：`make clean`
