# OpenSTA no clocks found：缺失与错名对照实验

**对应教程**：https://geek-doc.cn/eda/ts-opensta-no-clocks-found.html（上线后生效）

同一网表分别运行无 `create_clock`、正确端口约束和错误端口名三组 STA，观察 `report_clock_properties` 与 `report_checks` 的差异。

## 文件

- `top.v`：一级 DFF 加输出缓冲的网表，真实端口名是 `clk`。
- `experiment.lib`：只含 DFF 与 BUF 的实验 Liberty，带最小时序弧；不对应任何可制造 PDK。
- `no_clock.tcl`：完全不读 SDC。
- `fixed.sdc` / `fixed.tcl`：在 `[get_ports clk]` 上建立 10ns 时钟并复跑。
- `wrong_port.sdc` / `wrong_port.tcl`：故意把端口拼成 `clck`。
- `run1.log`：三组原始输出和各自退出码。

## 复现

安装 OpenSTA 后在本目录运行：

```bash
bash run.sh
```

也可用 `STA_BIN=/path/to/sta bash run.sh` 指定二进制。脚本逐组记录退出码，不因单组诊断错误中断后续对照。本文实验使用 Debian 官方 OpenSTA 2.0.17 包；库仅用于演示约束对象与路径报告，不代表签核时序。
