# vivado-xsim-timescale：XSIM 43-4099 timescale 不一致复现

**对应教程**：https://geek-doc.cn/fpga/beginner/ts-vivado-xsim-43-4099-timescale.html（上线后生效）

## 环境

- Vivado Simulator 2017.4（Windows，xvlog/xelab/xsim 批处理）
- 日期：2026-10-26

## 复现

- 报错：`xvlog dut_no_ts.v tb_ts.v && xelab tb_ts` —— DUT 无 `timescale`、TB 有，触发 `[XSIM 43-4099]`（见 `elab-err-43-4099.log`）
- 修复：`xvlog dut_with_ts.v tb_ts.v && xelab -debug typical tb_ts && xsim tb_ts -t xsim_run.tcl` —— 统一 timescale 后跑通并出 `dump.vcd`（见 `sim-fix-pass.log`）

## 文件

- `dut_no_ts.v` / `dut_with_ts.v`：同一 DUT 的无 / 有 timescale 两版
- `tb_ts.v`：带 timescale 的测试台
- `xsim_run.tcl`：VCD  dump 脚本（`xelab` 需加 `-debug typical` 才能 `open_vcd`）
