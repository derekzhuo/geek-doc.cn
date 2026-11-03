# Verilator 多线程仿真（--threads 1/2/4）对照实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-multithread.html

- `work.v`：参数化大设计，`WORKN` 个互相独立的 LFSR/累加工作单元 + 异或归约校验（默认 4096，可用 `+define+WORKN=1024` 覆盖）。
- `tb.cpp`：纯周期级 C++ testbench，不使用任何 `#` 延迟，可与 `--threads` 组合。
- `run.sh`：同一设计分别用 `--threads 1/2/4` 编译，大设计（4096 单元 / 50 万拍）与中等设计（1024 单元 / 20 万拍）各跑 3 次取 shell `time` 的 real 值，末尾输出 MTask 切分统计。

## 复现

```bash
make run          # 需要本机有 geek-eda:0.4-flow 镜像
make clean        # 删除全部 obj_* 构建目录
```

数字随机器、负载与核数变化；教程中的记录来自 6 核 12 线程的 Intel i7-9750H、容器内 `nproc=12`。
