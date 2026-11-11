# Verilator 波形导出 FST/VCD 最小实验

**对应教程**：https://geek-doc.cn/eda/flow-verilator-wave-fst.html

同一个 8 位计数器设计（`counter.v`）配一份 C++ harness（`tb_main.cpp`），分别用 Verilator 的 `--trace` 与 `--trace-fst` 编译，导出 VCD 与 FST 两种波形并对比体积。

## 环境

- Docker 镜像 `geek-eda:0.3-sta`（Verilator 5.020、GTKWave 3.3.116、fst2vcd、Xvfb）

## 复现

```bash
make vcd    # --trace 编译并运行，产出 wave.vcd
make fst    # --trace-fst 编译并运行，产出 wave.fst
make check  # ls -l / file / xxd 文件头 / fst2vcd 文本验证
```

或直接 `bash run.sh` 一次跑完全流程。

## 实测结果（2026-11-03，仿真 200000ns，40000 个落盘点）

| 文件 | 体积 |
|---|---|
| wave.vcd | 658740 字节 |
| wave.fst | 1519 字节 |

FST 约为 VCD 的 1/433。波形二进制产物（`wave.fst`/`wave.vcd`）与 `obj_vcd/`、`obj_fst/` 不入库。
