# Icarus Verilog 与 GTKWave 安装指南

本工程包只依赖两个免费工具：Icarus Verilog（编译并运行仿真，命令是 `iverilog` 和 `vvp`）与 GTKWave（查看 VCD 波形）。

## macOS

推荐 Homebrew：

```bash
brew install icarus-verilog gtkwave
```

验证：

```bash
iverilog -V | head -1
gtkwave --version
```

首次打开 GTKWave 如果被 Gatekeeper 拦截，到「系统设置 → 隐私与安全性」里允许一次即可。

## Ubuntu / Debian

```bash
sudo apt update
sudo apt install iverilog gtkwave
```

验证：

```bash
iverilog -V | head -1
which gtkwave
```

## Windows

1. 打开 Icarus Verilog 官网 <https://steveicarus.github.io/iverilog/>，下载 Windows 安装包（`.exe`）。
2. 安装向导中保持勾选 **Add executable folder(s) to the user PATH**，GTKWave 会一并安装。
3. 安装完成后重新打开 PowerShell，验证：

```powershell
iverilog -V
vvp -V
```

4. 本工程包的 Windows 入口不需要 make：

```powershell
.\run.ps1
```

如果提示脚本被执行策略拦截，只对当前窗口临时放开：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

## 常见问题

### `iverilog: command not found`

安装后必须重新打开终端窗口，PATH 才会生效。Windows 下确认安装向导的 PATH 选项没有取消勾选。

### 仿真能跑，但 `gtkwave` 打不开波形

先确认 VCD 文件已经生成：

```bash
ls lab01-clock-divider/sim_build/
```

能看到 `lab01.vcd` 说明仿真正常，问题只在 GTKWave 安装；macOS 可用 `brew reinstall gtkwave`，Windows 重新运行安装包选择修复。

### 中文路径导致的异常

尽量把工程放在纯英文路径下（例如 `~/projects/`），部分 Windows 工具链对非 ASCII 路径支持不佳。

### 版本要求

本工程包使用 Verilog-2005 语法（编译参数 `-g2005`）和 `$clog2` 系统函数，Icarus Verilog 11 及以上版本均可，推荐使用当前稳定版 13。
