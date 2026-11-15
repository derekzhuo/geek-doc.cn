# ts-xsim-elab-module-not-found — XSim elaboration 找不到模块的报错与修复对照

**对应教程**：<https://geek-doc.cn/eda/ts-xsim-elab-module-not-found.html>（上线后生效）

这个实验用一个最小与门工程，对照 XSim 2017.4 在编译单元不完整时的 elaboration 行为：只编译 testbench 时，`top_elab` 例化的 `and_gate` 没有进入 `work` 库，`xelab` 在静态展开阶段报 `[VRFC 10-2063]` 和 `[XSIM 43-3322]`；把 `and_gate.v` 与 `top_elab.v` 一起重新编译后，仿真快照才能建立并运行。

## 文件

| 文件 | 作用 |
|---|---|
| `and_gate.v` | 二输入与门 DUT |
| `top_elab.v` | 例化 `and_gate` 的 testbench |
| `run_sim.tcl` | 批处理仿真脚本，执行 `run all` 后退出 |
| `results/err-elab-module-missing.log` | 漏编译 DUT 时的实际输出 |
| `results/fix-elab-pass.log` | 编译完整文件列表并仿真成功的实际输出 |

## 复现步骤（Windows + Vivado 2017.4）

在 Vivado 2017.4 的命令行环境中进入本目录，先清理旧快照，再只编译 testbench：

```bat
rmdir /s /q xsim.dir
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat top_elab.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat top_elab
```

`xvlog` 可以单独分析 testbench，但 `xelab` 展开层次时找不到 `and_gate`，实际输出为：

```text
ERROR: [VRFC 10-2063] Module <and_gate> not found while processing module instance <u_gate> [top_elab.v:9]
ERROR: [XSIM 43-3322] Static elaboration of top level Verilog design unit(s) in library work failed.
```

修复时先删除旧的 `xsim.dir`，再把 DUT 和 testbench 一起交给 `xvlog`：

```bat
rmdir /s /q xsim.dir
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat and_gate.v top_elab.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat top_elab
D:\Xilinx\Vivado\2017.4\bin\xsim.bat top_elab -t run_sim.tcl
```

修复序列完成静态展开、数据流分析和快照构建，仿真输出：

```text
ELAB_SIM_RESULT a=1 b=1 y=1
```

这条结果对应 testbench 在 20ns 时把两个输入都置为 1，与与门真值表一致。排查同类问题时，先核对 `xvlog` 的文件列表和工程 sources 中的层次更新，再检查模块名与库名是否匹配。
