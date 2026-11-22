# flow-opensta-generated-clock

**对应教程**：https://geek-doc.cn/eda/flow-opensta-generated-clock.html（上线后生效）

OpenSTA 生成时钟约束实验：同一份 2 分频 DUT 配两版 SDC，对照「只约束主时钟、不声明生成时钟」与「用 `create_generated_clock` 声明分频输出」两种情况下 `check_setup` 与 `report_checks` 的真实行为，核验生成时钟域路径的 setup/hold slack，以及生成时钟与主时钟 latency 的继承关系。

## 重要边界

`teaching.lib` 是标量常数延迟的教学库（DFF_P、NAND2、BUF_X 三个单元），不代表任何真实工艺。主时钟 `clk` 周期 4.0 ns，经一级 BUF（0.10 ns）驱动分频触发器 `u_div`；分频输出再经一级 BUF（0.10 ns）构成生成时钟网络。`set_propagated_clock [all_clocks]` 后，生成时钟在捕获引脚 `u_cap/C` 的网络延迟为 0.10 + 0.20（触发器 clk-to-Q）+ 0.10 = 0.40 ns，全部数字均可在日志中逐行追溯。

## 文件

- `top.v`：2 分频 DUT。`u_div` 接成 D=~Q 的二分频，`u_launch` 在主时钟域发射数据，`u_cap` 在生成时钟域捕获。
- `teaching.lib`：最小教学 Liberty。
- `common.tcl`：读库、读网表、link。
- `nogen.sdc` / `gen.sdc`：两版约束，差别仅在是否声明 `create_generated_clock`。
- `nogen.tcl` / `gen.tcl`：两个场景的驱动脚本，输出时钟属性、setup 检查、hold 检查等报告。
- `run.sh`：依次运行两个场景，校验「无生成时钟版必须报 unclocked 引脚、生成时钟版必须出现 clk_div2 路径组且无 unclocked 告警」的预期。
- `results/`：本次运行的两份场景日志。

## 复现

```bash
make run
# 或使用本实验采用的镜像
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

本机已装 OpenSTA 时也可 `STA_BIN=sta bash run.sh`。注意 `sta` 进程在时序违例时退出码仍是 0，场景预期以 `run.sh` 末尾的 `RUN_RESULT` 行为准。

## 关键结果（2026-11-23 实测，OpenSTA 2.0.17）

| 检查项 | nogen：不声明生成时钟 | gen：声明 create_generated_clock |
|---|---|---|
| 时钟表 | 仅 clk（4.00 ns） | clk（4.00 ns）+ clk_div2（8.00 ns，generated） |
| unclocked 引脚 | 1 个：u_cap/C | 0 个 |
| 无约束端点 | 2 个：q_out、u_cap/D | 1 个：q_out（缺 output delay） |
| 跨域路径 u_launch → u_cap setup | 不分析 | slack 3.9000 ns（MET） |
| 同路径 hold | 不分析 | slack 0.0000 ns（MET） |
| 分频反馈路径 setup | slack 3.5500 ns（按 clk 直接分析） | slack 3.5500 ns（按 clk_div2 源沿 + 0.30 ns source latency 分析） |
