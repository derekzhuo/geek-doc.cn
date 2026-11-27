# XSim 43-3985：非法 xelab 选项与旧快照续跑对照

**对应教程**：https://geek-doc.cn/eda/ts-xsim-43-3985-unrecognised-option.html（上线后生效）

这个最小实验在 Vivado Simulator 2017.4 上验证两件事：`xelab -force` 会在参数解析阶段报 `[XSIM 43-3985]`，不会生成本次新快照；如果 PowerShell 用分号无条件继续执行，`xsim` 仍会加载目录里已有的旧快照并正常运行。修复脚本移除 `-force`，在每个原生命令后立即检查 `$LASTEXITCODE`，任何一步失败都停止后续流程。

## 文件

| 文件 | 作用 |
|---|---|
| `dut_toggle.v` / `tb_toggle.v` | 2 位计数器 DUT 与 testbench，72 ns 结束仿真 |
| `continuation_vcd.tcl` | 旧快照续跑时记录 `continuation.vcd`，捕获 VCD 命令错误并退出 |
| `fix_vcd.tcl` | 修复后的 VCD 流程，捕获打开、记录、运行和关闭阶段的错误 |
| `run_bad.ps1` | 建立基线快照，复现非法选项，再用分号无条件续跑 xsim |
| `run_fix.ps1` | 删除旧快照，逐步检查退出码并生成新快照与 `trace.vcd` |
| `results/baseline.log` | 合法基线编译与 elaboration 记录 |
| `results/bad-option.log` | 43-3985、真实 xelab 退出状态与快照时间戳核对结果 |
| `results/continuation-old-snapshot.log` | 旧快照加载路径、仿真结束位置与 xsim 退出状态 |
| `results/fix-pass.log` | 修复后的编译、快照重建、仿真和 VCD 检查记录 |
| `results/continuation.vcd` / `results/trace.vcd` | 两次运行生成的非空 VCD，本次均为 537 字节 |

## 复现步骤（Windows + Vivado 2017.4）

脚本中的工具目录为 `D:\Xilinx\Vivado\2017.4\bin`，安装位置不同则先修改 `$bin`。在 PowerShell 中进入本目录，执行：

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_bad.ps1
```

`run_bad.ps1` 先执行合法的 `xvlog` 和 `xelab -debug typical tb_toggle`，建立 `work.tb_toggle` 基线快照；随后执行 `xelab -debug typical -force tb_toggle`。该命令的预期结果是失败，日志应包含：

```bash
ERROR: [XSIM 43-3985] Problem with usage of options: unrecognised option '--force'.
```

脚本特意用 PowerShell 分号把后续 `xsim` 写在同一语句序列中，不根据前一命令的成功与否短路。本次记录为 `BAD_XELAB_EXIT=1`、`SNAPSHOT_TIMESTAMP_UNCHANGED=True`、`CONTINUATION_XSIM_EXIT=0`。后续 xsim 日志中的 `source xsim.dir/work.tb_toggle/xsim_script.tcl` 表明它加载了已有快照，不能把这轮正常退出当作非法选项已经修复。

再执行修复流程：

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_fix.ps1
```

修复脚本先删除旧的 `xsim.dir\work.tb_toggle`，然后依次运行：

```bat
D:\Xilinx\Vivado\2017.4\bin\xvlog.bat dut_toggle.v tb_toggle.v
D:\Xilinx\Vivado\2017.4\bin\xelab.bat -debug typical tb_toggle
D:\Xilinx\Vivado\2017.4\bin\xsim.bat tb_toggle -tclbatch fix_vcd.tcl
```

每个原生命令后都立即读取 `$LASTEXITCODE`，非零即退出。本次三项均为 0，日志重新出现 `Built simulation snapshot work.tb_toggle`，testbench 在 72 ns 到达 `$finish`，并生成非空 `trace.vcd`。

这里的结论只针对实际验证的 Vivado Simulator 2017.4。其他版本是否接受同名选项，应查看对应版本的帮助信息并单独测试。
