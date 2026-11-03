# flow-make-hardware-project

**对应教程**：https://geek-doc.cn/eda/flow-make-hardware-project.html

一个最小硬件工程的多目标 Makefile 示例：同一份 `rtl/counter4.v` 与 `tb/tb_counter.v`，用三个目标串起仿真、综合与清理。

## 目录

```text
.
├── Makefile          # sim / synth / lint / wave / clean 多目标
├── src.f             # iverilog filelist（一行一个源文件）
├── rtl/
│   └── counter4.v    # 4 位带使能加法计数器（异步复位、进位输出）
└── tb/
    └── tb_counter.v  # 自校验 testbench，打印 TEST PASS / TEST FAIL
```

## 复现方式

```bash
make sim      # 本机 iverilog 13 编译并 vvp 运行，期望 TEST PASS
make lint     # 只做语法检查（iverilog -tnull）
make synth    # 容器 geek-eda:0.4-flow 内 yosys 综合，网表落 build/
make clean    # 删除 build/
```

`make synth` 需要本机装有 Docker 且已拉取 `geek-eda:0.4-flow` 镜像；不用综合时只跑 `make sim` 即可，iverilog 12/13 均可。

## 增量依赖验证

首次 `make sim` 会执行 iverilog 编译与 vvp 运行；紧接着第二次 `make sim`，编译产物仍为最新，只运行 vvp；`touch rtl/counter4.v` 后再 `make sim`，因依赖比目标新，iverilog 会重新编译。
