# STA 时序报告提取 TCL 脚本模板实验

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-sta-report-extract-tcl.html

（教程上线后链接生效。）

用 OpenSTA 原生命令从时序分析结果中提取 WNS、TNS、违例路径条数并输出机器可读摘要的可复制 TCL 模板，配套两种工况（时钟 5 ns 全部 MET / 时钟收紧到 2 ns 两条链 SETUP VIOLATED）与无时钟、hold、CSV、阈值裕量等分支的真实验证。

## 目录内容

| 文件 | 说明 |
|---|---|
| `tiny.lib` | 最小教学 liberty：DFF_P（setup 0.10 ns、clk-to-q 0.20 ns）+ BUF_X1（延迟 0.15 ns） |
| `top.v` | 单级 DFF 路径，用于无时钟（unconstrained）分支 |
| `top2.v` | 同一发射触发器驱动 15 级、20 级两条缓冲链，分别到两个捕获触发器 |
| `constraints_met.sdc` / `constraints_vio.sdc` | 5 ns / 2 ns 两套时钟约束 |
| `extract_sta_summary.tcl` | 模板本体：参数区 + 路径收集 + 汇总 + 打印 |
| `case_*.tcl` | 六个工况驱动脚本 |
| `run.sh` | 依次跑全部工况，并把 STA_STATUS 映射为退出码（MET=0、VIOLATED=1、NO_CLOCKS=2） |

## 复现方式

需要 Docker（镜像 `geek-eda:0.3-sta`，Ubuntu 24.04 + OpenSTA 2.0.17）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

本机已安装 OpenSTA 2.0.17 时也可直接 `STA_BIN=sta bash run.sh`。
