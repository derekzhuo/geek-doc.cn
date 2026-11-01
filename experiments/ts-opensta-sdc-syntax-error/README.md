# ts-opensta-sdc-syntax-error

**对应教程**：https://geek-doc.cn/eda/ts-opensta-sdc-syntax-error.html（上线后生效）

手写 SDC 六类常见语法/语义错误的最小复现：命令拼错、缺 `-period`、花括号不配对、对象列表为空、数值带单位、`-waveform` 奇数个边沿点；外加一份全部写对的 `fixed.sdc`。

## 复现方式

需要安装 OpenSTA（实验环境为 Docker 镜像 `geek-eda:0.3-sta`，容器内 OpenSTA 2.0.17）：

```bash
bash run.sh
```

脚本依次运行 7 个用例（`e1_typo`、`e2_no_period`、`e3_brace`、`e4_empty`、`e5_unit`、`e6_waveform`、`fixed`），合并 stdout/stderr，每组末尾打印 `CASE_EXIT <name>=<退出码>`。

## 文件说明

- `experiment.lib`：仅含 DFF/BUF 最小时序弧的教学库；
- `top.v`：一个 DFF 加输出缓冲的最小网表，端口 `clk`/`d`/`q`；
- `e*.sdc` / `e*.tcl`：六类错误用例（SDC 与其加载脚本）；
- `fixed.sdc` / `fixed.tcl`：修复用例，`report_checks` 应输出 `slack (MET)`；
- `run.sh`：一键复现脚本。

注意：六类错误触发时 OpenSTA 进程退出码仍为 0，错误只能靠 stderr 文本与后续检查识别，不能只判断退出码。
