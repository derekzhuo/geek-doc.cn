# cocotb await 边沿误用导致挂死：最小复现工程

**对应教程**：https://geek-doc.cn/eda/ts-cocotb-fallingedge-misuse.html （上线后生效）

复现 cocotb 测试平台中 `RisingEdge` / `FallingEdge` / `Timer` 选型错误导致协程永远等不到的四类场景，并用退出码区分三种结局：

- 真挂死，被外部 `timeout 30` 杀掉，退出码 124；
- cocotb 内部 `with_timeout` 在仿真时间 230ns 抛 `SimTimeoutError`，快速失败，退出码 2；
- 仿真器事件队列耗尽，0ns 即 `SimFailure`（提示 `is your clock running?`），退出码 2；
- `Skipping simulation` 零测试但退出码 0（c5，对照现象）。

## 目录

```text
rtl/edge_dut.v            低有效复位同步寄存器 + 组合输出 comb_gate
cases/c1-reset-polarity/  低有效复位却等 RisingEdge(rst_n)，释放语句在 await 之后 -> 124
cases/c2-clock-not-started/  未启动 Clock 就等 RisingEdge(clk)，另有 Timer 后台活动 -> 124
cases/c2b-no-events/      未启动 Clock 且无任何事件 -> 0ns SimFailure，退出码 2
cases/c3-comb-edge/       在恒定不变的组合信号上等上升沿 -> 124
cases/c4-timer-vs-edge/   该用 Timer 固定延时却等信号边沿，with_timeout 200ns -> SimTimeoutError
cases/c5-skipping/        TOPLEVEL_LANG 与仿真器不匹配，Skipping simulation，退出码 0
cases/good/               四种边沿用法全部正确 -> TESTS=1 PASS=1
run.sh                    顺序跑全部用例，每个用例外包 timeout 30，记录退出码
run1.log                  2026-11-02 一次完整运行的原始输出
```

## 复现

需要装有 cocotb 2.1.0 与 Icarus Verilog 的环境（教程使用 Docker 镜像 geek-eda:0.3-sta）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta \
  bash -lc 'source /opt/venvs/cocotb/bin/activate && bash run.sh'
```

预期：c1/c2/c3 退出码 124，c2b/c4 退出码 2 且 c4 日志含 `SimTimeoutError`，c5 退出码 0 且只有一行 `Skipping simulation`，good 退出码 0 且 `TESTS=1 PASS=1 FAIL=0`。

单独跑某一组：

```bash
cd cases/good
make SIM=icarus
```

`sim_build/` 与 `results.xml` 为构建产物，不入库。
