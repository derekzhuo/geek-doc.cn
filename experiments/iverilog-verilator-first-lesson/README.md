# Icarus Verilog 与 Verilator 双仿真器最小对照（iverilog-verilator-first-lesson）

**对应教程**：

- <https://geek-doc.cn/eda/onboarding/iverilog-first-lesson.html>
- <https://geek-doc.cn/eda/onboarding/verilator-first-lesson.html>

同一份带使能与同步复位的 4 位计数器 RTL（`counter.v`）和同一个测试平台
（`tb_counter.v`），分别交给 Icarus Verilog 12.0 的事件驱动仿真与
Verilator 5.020 的周期级编译仿真，对照工具链形态、输出轨迹与编译耗时。

- **依赖**：iverilog/vvp、verilator（含 g++ 与 make）；纯标准 Verilog-2005/SystemVerilog 子集，无 IP
- **结构**：`rtl/counter.v` 是可综合 DUT，`rtl/tb_counter.v` 是带 `$display`/`$fatal` 的测试平台，`run.sh` 依次跑 Icarus 仿真、Verilator `--binary` 一体化编译仿真、`--lint-only` 静态检查与三回合编译耗时对照

## 设计要点

两个工具的根本差异在执行模型：Icarus 先把 RTL 编成 vvp 字节码再由事件循环
驱动，编译以毫秒计；Verilator 把 RTL 转成 C++ 再走系统编译器，首次编译要
几千毫秒，但换来周期级仿真的高吞吐。测试平台故意在时钟沿后立刻采样，两套
工具对非阻塞赋值更新与采样的调度口径不同，最终一拍观测值相差 1
（Icarus 11、Verilator 12），测试平台用 `VERILATOR` 宏隔离各自预期——这个
差异本身就是入门阶段必须建立的调度认知，而不是工具 bug。

## 复现

```bash
bash run.sh
```

输出四段：Icarus 仿真轨迹与 PASS 行、Verilator 编译后仿真轨迹与 PASS 行、
lint-only 结论、两工具各 3 次编译毫秒数与中位数。`obj_dir/` 与 vvp 字节码
是生成物，已在 `.gitignore` 排除。

## 实测摘要（2026-11-14，Ubuntu 24.04 容器，i7-9750H / 12 vCPU）

| 指标 | Icarus Verilog 12.0 | Verilator 5.020 |
|---|---:|---:|
| 编译中位耗时 | 7 ms | 3633 ms |
| 执行模型 | vvp 字节码 + 事件循环 | RTL→C++→本机二进制，周期级 |
| 最终观测计数 | 11 | 12（采样口径差一拍，宏隔离预期） |
| lint-only 独立检查 | 无该模式，编译即检查 | 支持，DUT 单模块零告警 |

完整逐轮输出见教程附带的运行记录。
