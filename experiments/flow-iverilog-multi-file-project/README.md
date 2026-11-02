# iverilog 多文件工程组织：最小三模块实验

**对应教程**：https://geek-doc.cn/eda/flow-iverilog-multi-file-project.html

一个最小的多模块 Verilog 工程：`alu`（8 位运算单元）+ `regfile`（4x8 寄存器堆）+ `datapath`（顶层，例化前两者），外加一个自检 testbench `tb_top`。用于演示 iverilog 编译多文件工程的三种组织方式：

1. 命令行直接列出全部文件（顺序随意，iverilog 全量扫描后按模块依赖自行确定编译顺序）；
2. `-f filelist.f` 从文件清单读取源文件；
3. `-y rtl` 库目录：命令行只给 testbench，子模块按「模块名 == 文件名」自动检索。

## 复现

```bash
make run      # 依次跑四种编译（含颠倒文件顺序）+ 两个报错检查点
# 或单独跑：
make cli      # 方式 1：命令行列文件
make flist    # 方式 2：-f filelist.f
make lib      # 方式 3：-y rtl 库目录
make clean
```

环境：Icarus Verilog 13.0（`iverilog` / `vvp`）。

## 目录

```
rtl/alu.v        ALU 模块（文件名须与模块名一致，-y 检索依赖此约定）
rtl/regfile.v    寄存器堆模块
rtl/datapath.v   顶层数据通路
tb/tb_top.v      自检 testbench（打印 [tb] PASS / FAIL）
filelist.f       方式 2 的文件清单
Makefile / run.sh
```
