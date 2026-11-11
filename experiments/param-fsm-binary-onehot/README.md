# param-fsm-binary-onehot

**对应教程**：https://geek-doc.cn/chip-design/beginner/param-fsm-binary-onehot.html

同一份参数化 FSM（有界线性往返控制器）在 binary / gray / one-hot 三种状态编码、
4/8/16 三个状态数档位下的真实综合对比：Icarus Verilog 行为等价性检查，
Yosys 0.33 映射到教学最小 liberty 后统计触发器/单元/面积，OpenSTA 2.0.17
在统一 10 ns 时钟约束下报告最差 setup slack。

## 目录

- `rtl/fsm_walker.v` — 参数化 FSM（`NSTATES` 状态数，`ENC` 0=binary / 1=gray / 2=one-hot）
- `tb/tb_fsm_walker.v` — 同激励下三编码输出逐拍比对
- `liberty/teaching.lib` — 教学用最小标准单元库（DFF_P + NAND2_X1 + INV_X1 + BUF_X1，标量延时，不对应真实工艺）
- `constraints.sdc` — 10 ns 时钟周期
- `run.sh` — 流程：等价性仿真 → 9 次综合+stat → 9 次 STA，汇总 `work/results.csv`
- `plot.py` — 读 `work/results.csv` 画两张 SVG 对比图（本机 matplotlib venv）

## 复现

```bash
make run        # 需要本机有 geek-eda:0.4-flow 镜像与 docker
# 只跑行为等价性：
make sim
# 出图（跑完 run.sh 之后）：
python3 -m venv .venv && . .venv/bin/activate && pip install matplotlib
python plot.py
```

教学库单元延时为标量常数，绝对频率数字没有工程意义；实验只回答
「同一设计、同一库、同一约束下，三种编码的相对差异与随状态数的变化趋势」。
