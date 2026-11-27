# XSim VRFC 10-552 匿名顺序块声明复现

**对应教程**：https://geek-doc.cn/eda/ts-xsim-vrfc-10-552-unnamed-block-declaration.html

这个最小实验在 Windows 上的 Vivado Simulator 2017.4 中比较三种 Verilog 写法。三份测试台的激励相同：`count` 从 0 开始，10 ns 后加 3，再于 20 ns 结束仿真。唯一变量是 `integer count` 所在的作用域。

| 源文件 | 声明位置 | 2017.4 实测结果 |
|---|---|---|
| `tb_unnamed_bad.v` | 匿名 `initial begin` 内 | `xvlog` 报 VRFC 10-552 与 10-1040，退出码 1，不运行 elaboration |
| `tb_named_block.v` | `initial begin : stimulus` 命名块内 | 编译、展开、运行均成功，20 ns 输出 `DECLARATION_SCOPE_SIM_PASS count=3` |
| `tb_module_scope.v` | module 作用域 | 编译、展开、运行均成功，20 ns 输出同一 PASS 结果 |

## 环境

- Windows 64 位工作站
- Vivado Simulator 2017.4，SW Build 2086221
- `xvlog.bat`、`xelab.bat`、`xsim.bat`
- 实验日期：2026-11-28

脚本中的工具路径固定为 `D:\Xilinx\Vivado\2017.4\bin`。安装位置不同，只需修改三个 PowerShell 脚本里的 `$bin`。

## 复现错误

在此目录打开 PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_bad.ps1
```

脚本只调用一次 `xvlog.bat tb_unnamed_bad.v`。原始工具诊断为：

```text
ERROR: [VRFC 10-552] declarations not allowed in unnamed block [.../tb_unnamed_bad.v:4]
ERROR: [VRFC 10-1040] module tb_unnamed_bad ignored due to previous errors [.../tb_unnamed_bad.v:3]
```

`run_bad.ps1` 将非零 `xvlog` 退出码视为预期复现结果，记录 `BAD_XVLOG_EXIT=1` 后自行以 0 退出；它不会调用 `xelab`。这不表示坏源码编译成功，判断依据是日志中的工具错误和 `BAD_XVLOG_EXIT`。

## 修复一：给顺序块命名

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_named.ps1
```

等价的三条原生命令为：

```bat
xvlog.bat tb_named_block.v
xelab.bat tb_named_block -s named_block_snapshot
xsim.bat named_block_snapshot -R
```

脚本逐步检查退出码，前一步失败便停止。结果日志确认 `Built simulation snapshot named_block_snapshot`，随后输出：

```text
DECLARATION_SCOPE_SIM_PASS count=3
$finish called at time : 20 ns : File ".../tb_named_block.v" Line 14
NAMED_XSIM_EXIT=0
```

## 修复二：把声明移到 module 作用域

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_module_scope.ps1
```

等价命令为：

```bat
xvlog.bat tb_module_scope.v
xelab.bat tb_module_scope -s module_scope_snapshot
xsim.bat module_scope_snapshot -R
```

结果日志确认 `Built simulation snapshot module_scope_snapshot`，20 ns 输出 `DECLARATION_SCOPE_SIM_PASS count=3`，三个步骤退出码均为 0。

## 结果记录

`results/` 保存本次 2017.4 实验的三份文本日志：

- `err-unnamed-block.log`：匿名块声明失败，以及未继续 elaboration 的记录。
- `fix-named-block.log`：命名块修复后的编译、展开和仿真输出。
- `fix-module-scope.log`：模块作用域修复后的完整输出。

这些结果只描述本文列出的 Verilog 模式和 Vivado Simulator 2017.4，不外推为其他语言模式或其他版本的诊断行为。
