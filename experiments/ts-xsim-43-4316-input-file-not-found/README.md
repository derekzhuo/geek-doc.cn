# XSim 43-4316 输入文件找不到复现

**对应教程**：https://geek-doc.cn/eda/ts-xsim-43-4316-input-file-not-found.html

这个最小工程用同一个 4 位计数器验证四种路径场景：文件名拼错、当前工作目录错误、正确相对路径、正确绝对路径。设计逻辑始终不变，只有传给 `xvlog` 的路径和命令执行目录不同。

## 环境

- Windows 64 位工作站
- Vivado Simulator 2017.4，SW Build 2086221
- 脚本中工具目录为 `D:\Xilinx\Vivado\2017.4\bin`，其他安装位置需修改三个运行脚本中的 `$bin`
- 示例路径不要包含空格；脚本会打印 `Get-Location`、`Test-Path` 和 `Resolve-Path`，便于核对实际输入

## 运行

在本目录打开 PowerShell，依次执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_typo.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_wrong_cwd.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_fixed.ps1 -Mode relative
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_fixed.ps1 -Mode absolute
```

也可以一次运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_all.ps1
```

前两个脚本把 xvlog 的预期失败作为实验结果，脚本本身在确认失败后返回 0，但会保留 `TYPO_XVLOG_EXIT=1` 或 `WRONG_CWD_XVLOG_EXIT=1`，并明确记录没有执行 elaboration。两个修复脚本逐步检查 xvlog、xelab、xsim 的原生退出码，任一阶段失败就停止。

## 已验证结果

2026-11-28 在 Vivado Simulator 2017.4 上得到：

| 场景 | 输入与目录 | 结果 |
|---|---|---|
| 文件名拼错 | 实际文件为 `tb_counter.v`，命令写 `tb_counter4.v` | `ERROR: [XSIM 43-4316] Can not find file: tb_counter4.v`，xvlog 退出码 1 |
| 工作目录错误 | `tb_counter.v` 在 `src`，当前目录为 `wrong-cwd` | 同一 43-4316，xvlog 退出码 1；绝对路径的 Test-Path 为 True，相对路径为 False |
| 正确相对路径 | 从 `fixed-relative` 使用 `..\src\counter4.v` 和 `..\src\tb_counter.v` | 生成 `relative_snapshot`，50 ns 输出 `INPUT_PATH_SIM_PASS count=4` |
| 正确绝对路径 | 两个源文件均使用绝对路径 | 生成 `absolute_snapshot`，同样在 50 ns 输出 `count=4` |

`results/` 保存四份结果日志。公开示例目录统一写成 `C:\eda-lab\xsim-input-file`；诊断文本、退出码、仿真时间和源码行号保留实测内容。

修复场景的关键命令分别是：

```bat
xvlog.bat ..\src\counter4.v ..\src\tb_counter.v
xelab.bat tb_counter -s relative_snapshot
xsim.bat relative_snapshot -R
```

```bat
xvlog.bat C:\eda-lab\xsim-input-file\src\counter4.v C:\eda-lab\xsim-input-file\src\tb_counter.v
xelab.bat tb_counter -s absolute_snapshot
xsim.bat absolute_snapshot -R
```

运行后，四个场景目录中的 `xsim.dir`、`.Xil` 和工具日志可以删除；`src`、脚本和 `results` 是复现所需的源材料，不要清理。
