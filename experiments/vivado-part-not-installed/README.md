# vivado-part-not-installed：Vivado 指定器件未安装复现

**对应教程**：<https://geek-doc.cn/fpga/beginner/ts-vivado-part-not-installed.html>

## 环境

- Windows + Vivado 2017.4
- 已安装免费 Artix-7 器件：`xc7a35tcpg236-1`
- 未安装示例中的 Spartan-6 器件：`xc6slx9-tqg144-2`
- 日期：2026-11-13

## 文件说明

- `part_missing.tcl`：用未安装的 `xc6slx9-tqg144-2` 创建工程，复现 `Device 21-436` 与 `Coretcl 2-106`。
- `part_installed.tcl`：改用本机已安装的 `xc7a35tcpg236-1` 创建工程，验证修复路径。
- `v13_err.tcl`、`v13_fix.tcl`：保留原始实验命令中的文件名，分别薄封装到上面两个语义化脚本。
- `part_probe.tcl`：依次探测 Spartan-6、Versal 和错误 Artix-7 编号，再用已安装 Artix-7 做对照。
- `list_parts.tcl`：导出 `get_parts` 返回的本机已安装器件清单。
- `list-parts.log`：上述脚本在实验机上导出的已安装器件清单，共 2074 个 part。
- `run-vivado.ps1`：Windows PowerShell 批处理包装器，会调用 Vivado batch mode，并把输出写入日志。

## 复现方式

在本目录打开 PowerShell，按实际安装路径调整 `run-vivado.ps1` 中的 Vivado 路径后执行：

```powershell
powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl v13_err.tcl -Log err-part-missing.log
powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl v13_fix.tcl -Log fix-part-installed.log
powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl part_probe.tcl -Log part-probe.log
powershell -ExecutionPolicy Bypass -File run-vivado.ps1 -Tcl list_parts.tcl -Log list-parts.log
```

也可以直接调用 Vivado 命令行：

```powershell
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source part_missing.tcl
D:\Xilinx\Vivado\2017.4\bin\vivado.bat -mode batch -source part_installed.tcl
```

## 关键结果

坏例日志中 `get_parts -quiet xc6slx9-tqg144-2` 返回 0，并出现：

```text
WARNING: [Device 21-436] No parts matched 'xc6slx9-tqg144-2'
ERROR: [Coretcl 2-106] Specified part could not be found.
```

修复对照中 `get_parts -quiet xc7a35tcpg236-1` 返回 1，并成功创建工程：

```text
INSTALLED_PART_CREATED xc7a35tcpg236-1
```
