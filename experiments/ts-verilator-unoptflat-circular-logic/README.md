# ts-verilator-unoptflat-circular-logic

**对应教程**：https://geek-doc.cn/eda/ts-verilator-unoptflat-circular-logic.html（上线后生效）

Verilator `%Warning-UNOPTFLAT: Signal unoptimizable: circular logic` 的最小复现与修复对照。

## 文件

- `loop_bad.v`：两条互斥 assign 构成的组合逻辑环（x 依赖 z、z 依赖 x），lint 必报 UNOPTFLAT。
- `loop_fix.v`：把 z 打一拍寄存（z_q），组合环被时序单元切断，lint 干净。
- `run.sh`：一键复现脚本。
- `logs/`：真机跑出的原始输出（Verilator 4.038，云主机 Docker 容器内）。

## 复现

本机装有 verilator（4.x 均可）时：

```sh
sh run.sh
```

没有本地 verilator 可用官方镜像（本次实录即此方式）：

```sh
docker run --rm -v "$PWD":/work -w /work verilator/verilator:4.038 --lint-only -Wall loop_bad.v
docker run --rm -v "$PWD":/work -w /work verilator/verilator:4.038 --lint-only -Wall loop_fix.v
```

预期：`loop_bad.v` 报 `%Warning-UNOPTFLAT` 并以 exit 1 退出；`loop_fix.v` 无任何输出、exit 0。
