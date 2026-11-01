# ts-opensta-report-unconstrained

**对应教程**：https://geek-doc.cn/eda/ts-opensta-report-unconstrained.html（上线后生效）

OpenSTA `report_checks` 整份报告端点全部 unconstrained 的三种真实根因复现：时钟建到错误网络、时钟端口对但内部缓冲在 Liberty 中缺时序弧导致时钟不传、SDC 未被 source（含 link 之前过早 source）。

## 复现

```bash
bash run.sh
```

容器内运行：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

## 场景

| 用例 | 根因 |
|---|---|
| `case1_wrong_net.tcl` | create_clock 建到数据缓冲内部脚，clk 网络无时钟 |
| `case2_broken_buf.tcl` | 时钟端口正确，但 `broken.lib` 中 CLK_BUF 无 timing arc，时钟止于缓冲 |
| `case3_nosource.tcl` | SDC 文件根本未被 source |
| `case3b_early_source.tcl` | SDC 在 read_liberty/link 之前 source，报 no network has been linked |
| `fixed.tcl` | `good.lib` 含完整时序弧、link 后 source 正确 SDC，slack MET |

## 文件

- `top.v`：clk 经内部 CLK_BUF 进 DFF 的最小设计
- `good.lib` / `broken.lib`：教学用最小 Liberty，后者的 CLK_BUF 缺时序弧
- `constraints.sdc`：10ns 时钟 + 1ns 输入/输出延迟
- `diag.tcl`：all_clocks 源点与时钟网络逐脚连通性诊断过程
