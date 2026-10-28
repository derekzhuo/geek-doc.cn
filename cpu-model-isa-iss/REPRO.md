---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/cpu-model-isa-iss/`，配套页面 https://geek-doc.cn/demos/cpu-model-isa-iss/


# cpu-model-isa-iss —— RV32I 子集解释器 ISS + 统计 CPI 模型

> **代码获取**：本实验源码已同步至公开仓库 [derekzhuo/geek-doc.cn](https://github.com/derekzhuo/geek-doc.cn?utm_source=geek-doc.cn&utm_medium=doc&utm_campaign=repo_clone)，clone 即跑：`git clone --depth 1 https://github.com/derekzhuo/geek-doc.cn.git`，目录在 `demos/cpu-model-isa-iss/`。
>
> 配套文档：[指令集架构建模：RISC-V / ARM / x86 怎么写成可执行的 ISS](/cpu-model/isa-modeling-riscv-arm-x86.md)（CPU 微架构建模系列 A2）。

## 一、实验目的

把硅前建模的「**功能模型 / 性能模型分离**」做成可运行、可观测的最小系统：

1. **Part 1 功能模型（ISS）**：手写一个 RV32I 子集解释器，逐位复现架构可见状态（32 个 GPR、PC、字节内存），跑一个真实的数组求和循环，输出正确结果与指令 mix；全程不数周期、不建流水线。
2. **Part 2 统计式性能模型**：ISS 每执行一条指令回调一条 trace（指令类别 + 分支是否跳转），独立的 CPI 模型按 `base CPI=1 + 分支误预测惩罚 + load miss 惩罚` 折算周期，对同一条 trace 扫两组微架构参数，得到不同 IPC。

要看到的核心现象：**功能结果（内存里的和）与微架构假设无关、恒定正确；IPC 却随预测器/缓存参数变化数倍。**

## 二、快速开始

```bash
make            # g++ -O2 -std=c++17 -Wall
make run        # 或 ./iss
```

无第三方依赖（不需要安装 SystemC），任何支持 C++17 的 g++/clang 均可。本站在 CentOS 7 + devtoolset-10（GCC 10.2.1）实测通过。

## 三、实测输出

```bash
================ Part1 功能模型（ISS 执行结果）================
数组长度 N        = 32
期望累加和        = 528
ISS 内存[0x0080]   = 528  [PASS]
退出时 PC         = 0x28
总执行指令数      = 166
指令 mix         :  alu=101  branch=32  load=32  store=1
（功能模型全程不知道周期，也没有流水线）

================ Part2 统计式性能模型（同一条 trace 扫参数）================
trace: 总指令=166  分支=32(taken 31)  load=32  store=1  jump=0
模型假设: base CPI=1, 误预测惩罚=15 周期, load miss 惩罚=200 周期
现代预测器 + 热缓存  (p=2%,  miss=2%)   -> cycles=     304  IPC=0.547
弱预测器 + 冷/大工作集(p=15%, miss=20%)  -> cycles=    1518  IPC=0.109

结论: 功能结果与微架构假设无关(恒为 528)；IPC 随预测/缓存假设变化，
     因此功能模型与性能模型解耦后可独立替换、独立校准。
```

## 四、代码结构导读

| 部分 | 关键内容 |
|---|---|
| 编码小工具 | `enc_R/I/S/B/J/LUI`：把助记指令拼成 RV32I 机器字，含 B/J 型打散立即数的重组 |
| `struct Iss` | 架构状态（GPR/PC/mem）、`step()` 取指-译码-执行主循环、符号扩展 `sext`、`x0` 写入丢弃、`EBREAK` 停机 |
| `struct CpiModel` | 只吃 trace 计数，按误预测率 / load miss 率折算周期与 IPC |
| `buildProgram()` | 构造数组求和循环（`LW/ADD/ADDI/BNE`），数据放 `0x1000`，结果写 `0x80` |
| `main` | 装载程序与数据 → 挂 trace 回调 → 一次运行 → 打印功能结果 + 两组参数下的 IPC |

## 五、动手扩展建议

- 把 `N` 改大，观察指令 mix 中分支/load 占比与 IPC 的变化（循环体固定，prologue/epilogue 被摊薄）。
- 调整 `CpiModel::cycles` 的惩罚参数（如误预测 15→20、miss 200→300），体会「内存延迟主导 IPC」。
- 给 `Iss` 增加 `JAL`/`BLT` 的处理并写一个函数调用程序，观察跳转 trace；再尝试实现 `ADDI` 立即数越界（如 `0x800`）复现实验中符号扩展导致的段错误。
- 把概率惩罚换成逐拍的流水线资源/依赖模型（A3 的方向），让 stall 气泡从结构里长出来。

## 一句话总结

这个实验把硅前建模的功能与性能分离跑通：RV32I 解释器保证功能结果恒定正确，独立的统计 CPI 模型吃同一条指令 trace，通过替换预测器和缓存参数让 IPC 变化数倍，证明两类模型可以独立替换和校准。
