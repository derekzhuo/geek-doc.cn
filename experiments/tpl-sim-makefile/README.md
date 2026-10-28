# tpl-sim-makefile —— 仿真工程通用 Makefile 模板

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-sim-makefile.html （上线后生效）

一个可直接搬进工程的仿真 Makefile 模板：`SIM ?= iverilog` 双后端切换
（Icarus Verilog 走编译 + vvp；Verilator 走 `--binary --timing` 直接编译出可执行仿真器），
目标含 `all / sim / lint / wave / clean / regress`，源文件列表与参数传递（`-P` / `-G`）集中在头部变量。

## 文件

- `Makefile` —— 模板本体
- `counter.v` —— 示例 DUT：参数化位宽同步计数器
- `tb_counter.v` —— 自检 testbench（下降沿驱动激励，PASS/FAIL 打印）

## 复现

```bash
make                 # iverilog 后端仿真
make SIM=verilator   # verilator 后端（本机无 verilator 时可用 docker 镜像传入 VERILATOR 变量）
make lint            # verilator -Wall 静态检查
make regress         # 多 SEED 回归示范
```

iverilog 13.0 / Verilator 5.020 实测双后端 PASS。
