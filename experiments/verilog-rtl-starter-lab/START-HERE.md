# START HERE：10 分钟跑通第一个实验

这份指南带你完成工具安装、跑通 Lab 01、打开第一张波形。完成后再回到 [README](README.md) 按顺序做其余四个实验。

## 1. 安装工具

### macOS

```bash
brew install icarus-verilog gtkwave
```

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install iverilog gtkwave
```

### Windows

到 Icarus Verilog 官网下载 Windows 安装包，安装时勾选把可执行文件加入 PATH。GTKWave 已随安装包附带。详细步骤和常见问题见 [docs/install-iverilog-gtkwave.md](docs/install-iverilog-gtkwave.md)。

## 2. 验证安装

```bash
iverilog -V
vvp -V
```

两条命令都能打印版本号即安装成功。Windows 下如果提示「找不到命令」，关闭当前 PowerShell 窗口重新打开，让 PATH 生效。

## 3. 跑 Lab 01

在工程包根目录执行：

```bash
make lab01-clock-divider
```

Windows 没有 make 时，直接调用编译器两条命令：

```powershell
iverilog -g2005 -I common -o lab01-clock-divider/sim_build/sim.vvp lab01-clock-divider/tb/tb_clock_divider.v lab01-clock-divider/rtl/clock_divider.v
vvp lab01-clock-divider/sim_build/sim.vvp
```

期望看到四行 `PASS`，结尾是：

```text
RESULT: PASS
```

如果出现 `RESULT: FAIL`，仿真退出码不为 0，说明环境或代码有问题，先不要往后做。

## 4. 打开波形

```bash
gtkwave lab01-clock-divider/sim_build/lab01.vcd
```

在 GTKWave 左侧把 `tb_clock_divider`、`dut` 下的信号添加到波形区，重点观察：

- `clk`：10 ns 周期的输入时钟；
- `dut.cnt`：0→1→2→3 循环计数；
- `out`：每 4 个 `clk` 翻转一次。

对照 [lab01-clock-divider/README.md](lab01-clock-divider/README.md) 里的「波形怎么读」一节，确认你看到的现象和文档一致。

## 5. 跑一次全量自检

回到工程包根目录：

```bash
make test
```

五个实验全部通过时，最后一行是 `RESULT: PASS 5/5`。到这里环境已经完全就绪，可以按 README 的实验顺序正式学习了。
