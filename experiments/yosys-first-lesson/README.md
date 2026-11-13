# Yosys 综合入门：一份计数器 RTL 综合后变成了什么（yosys-first-lesson）

**对应教程**：<https://geek-doc.cn/eda/onboarding/yosys-first-lesson.html>（上线后生效）

把 Icarus/Verilator 仿真用过的同一份 4 位计数器 RTL（`rtl/counter.v`）交给
Yosys 0.33 做通用（generic）综合，观察 `read_verilog → synth → stat → write_verilog`
全流程，并直接阅读综合出的网表：行为级的 `count <= count + 1` 被展开成
4 个带使能与同步复位的 D 触发器（`$_SDFFE_PN0P_`）加一组门级组合逻辑。

- **依赖**：yosys（0.33 实测）；无需任何目标工艺库，本实验只综合到 Yosys 内置通用单元
- **结构**：`rtl/counter.v` 是可综合 DUT（与 iverilog-verilator-first-lesson 同源），
  `synth.ys` 是综合脚本，`run.sh` 执行综合、打印网表并统计通用单元，
  网表产物落在 `build/`（已 gitignore）

## 设计要点

仿真器回答「这个设计行为对不对」，综合器回答「这个设计能映射成哪些硬件单元」。
`synth` 一条命令内部串起展平、优化、FSM 提取、代数优化与通用单元映射，
`stat` 给出综合后的线网与单元清点，`write_verilog -noexpr` 导出保留单元实例的
门级网表——它是后端工艺映射、形式验证或门级仿真的输入。4 位计数器综合后恰好是
10 个单元：4 个 D 触发器保存状态，6 个门（XOR/XNOR/NAND/ANDNOT/NOT）实现
二进制加一与进位链，对照 RTL 可以逐位追溯。

## 复现

```bash
bash run.sh
```

输出三段：Yosys 版本与完整综合 pass 日志（含 `stat` 统计）、综合后网表
`build/counter_netlist.v` 全文、网表中通用单元的分类计数。

## 实测摘要（2026-11-14，Ubuntu 24.04 容器，Yosys 0.33）

| 项目 | 结果 |
|---|---|
| 综合后单元总数 | 10 |
| 时序单元 | `$_SDFFE_PN0P_` × 4（每比特一个带使能、同步复位 D 触发器） |
| 组合单元 | `$_XOR_` × 2、`$_XNOR_` × 1、`$_NAND_` × 1、`$_ANDNOT_` × 1、`$_NOT_` × 1 |
| 线网 / 线网比特 | 8 / 17 |
| CHECK pass | 0 problems |
| 综合耗时（CPU user） | 0.08 s |

完整逐 pass 输出见教程附带的运行记录。
