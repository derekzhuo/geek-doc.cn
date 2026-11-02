# flow-iverilog-sdf-post-sim

**对应教程**：https://geek-doc.cn/eda/flow-iverilog-sdf-post-sim.html

用 Yosys 0.33 把 RTL 综合成门级网表、生成一份教学用最小 SDF 延时标注，再用 Icarus Verilog 12.0 分别跑 RTL 前仿与 SDF 反标门级后仿的最小实验。被测设计是带使能与进位的 4 位计数器（`counter.v`）。

## 文件

- `counter.v`：RTL 设计（四个标量触发器，使综合后实例名不带位选括号）
- `tb_counter.v`：同一个 testbench，定义 `GATES` 宏时调用 `$sdf_annotate`
- `synth.ys`：Yosys 脚本，`synth -flatten` 后 `write_verilog -noattr -noexpr netlist.v`
- `gen_sdf.awk`：从门级网表实例生成最小 SDF（按门类型统一赋延时，单位 ps）
- `gates_sim.v`：网表实际用到的 7 种 Yosys 通用门（`$_NOT_`/`$_NAND_`/`$_OR_`/`$_ANDNOT_`/`$_XOR_`/`$_XNOR_`/`$_DFFE_PN0P_`）的仿真模型，specify 路径默认零延时
- `counter.sdf`：生成的教学 SDF 样例（门 18-40ps，触发器 C->Q 70-80ps）
- `run.sh`：一条命令走完综合、SDF 生成、前仿、后仿

延时数字为本教学实验自定，不代表任何真实工艺；产线流程由实现工具结合 Liberty/SPEF 写出 SDF。

## 复现

需要本机装有 Docker 与镜像 `geek-eda:0.3-sta`（Yosys 0.33 + Icarus Verilog 12.0）：

```bash
make run       # 全流程，末尾前仿/后仿都应打印 PASS
make presim    # 只跑 RTL 前仿
make gatesim   # 只跑 SDF 反标门级后仿
make clean     # 删除 netlist.v 与 *.vvp（counter.sdf 会重新生成）
```

关键现象：前仿中 q 在时钟沿当拍变化、carry 在 q==15 的同一时刻拉高；后仿中 q 晚约 80ps 更新，carry 经四级组合门再晚约 81ps（如 290ns 时钟沿对应 290161ps），两种仿真 19 个周期的功能比对均为 PASS。
