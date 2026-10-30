# 从这里开始

这是一个同步 FIFO 入门工程。目标是先跑通自校验仿真，再打开波形观察读写指针和空满标志。

## 1. 准备工具

必须安装 Icarus Verilog，并确认 `iverilog` 和 `vvp` 已加入 `PATH`。查看波形还需要 GTKWave；只在命令行运行测试时不依赖 GTKWave。

Ubuntu / Debian：

```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave
```

macOS（使用 Homebrew）：

```bash
brew install icarus-verilog gtkwave
```

Windows：安装 Icarus Verilog，将其 `bin` 目录加入 `PATH`；需要查看波形时再安装 GTKWave。重新打开终端后执行：

```powershell
iverilog -V
vvp -V
```

## 2. 运行测试

在工程根目录执行一条命令。

Windows PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
```

Linux / macOS：

```bash
make test
```

没有 `make` 时也可以直接运行：

```bash
bash scripts/run.sh
```

测试通过时，输出末尾包含：

```bash
RESULT: PASS
```

脚本会同时把完整输出保存到 `out/sim.log`。编译失败、仿真失败或未出现通过标志时，脚本返回非零退出码。

## 3. 打开波形

仿真会生成 `out/sync_fifo.vcd`：

```bash
gtkwave out/sync_fifo.vcd
```

建议先添加这些信号：

- `clk`、`rst_n`
- `wr_en`、`wr_data`、`full`
- `rd_en`、`rd_data`、`empty`
- `dut.wptr`、`dut.rptr`、`dut.used`

先观察复位结束后 `wptr` 随成功写入递增，再观察 `rptr` 随成功读取递增；当两者相差 FIFO 深度时，`full` 应当有效。

## 4. 接下来读什么

1. [接口与时序规格](docs/01-spec.md)：明确每个信号和边界行为。
2. [README](README.md)：了解目录、测试范围和常用命令。
3. `rtl/sync_fifo.v`：阅读 FIFO 实现。
4. `tb/tb_sync_fifo.v`：理解 scoreboard 如何自动检查数据。

## 5. 常见问题

- **提示找不到 `iverilog` 或 `vvp`：** 工具未安装，或安装目录没有加入当前终端的 `PATH`。
- **测试失败：** 先查看 `out/sim.log` 中第一条 `MISMATCH` 或 `FLAG ERROR`，不要只看最后的失败汇总。
- **没有生成波形：** 仿真没有正常执行到初始化阶段，先解决编译或仿真错误。
- **Windows 禁止运行脚本：** 使用上面的 `powershell -ExecutionPolicy Bypass -File` 命令，不需要修改系统执行策略。
