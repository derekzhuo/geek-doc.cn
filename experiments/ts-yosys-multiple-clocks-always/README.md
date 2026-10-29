# ts-yosys-multiple-clocks-always

**对应教程**：https://geek-doc.cn/eda/ts-yosys-multiple-clocks-always.html（上线后生效）

Yosys 0.33 对单个 `always` 过程混用两个时钟边沿的最小复现，以及按时钟域拆成两个过程后的修复对照。

## 文件

- `multi_clock_bad.v`：同一过程敏感于 `clk_a` 与 `clk_b` 的上升沿，`proc_dff` 报 `Multiple edge sensitive events found for this signal!`。
- `multi_clock_fixed.v`：每个寄存器留在自己的时钟域，两个 `always` 各自只有一个时钟边沿。
- `run.sh`：依次运行坏例与修复例，检查两者退出码分别为 1 和 0。
- `run1.log`：本次真实运行的完整输出。

## 复现

本机已安装 Yosys 时：

```bash
bash run.sh
```

使用本文相同容器版本时，在本目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本期望坏例以 1 退出、修复例以 0 退出，最后打印 `RESULT: PASS`。修复证据仅限 Yosys `hierarchy/proc/check` 通过，不代表做了功能等价证明。

测试环境：Yosys 0.33 (git sha1 2584903a060)，`geek-eda:0.2` Docker 镜像。
