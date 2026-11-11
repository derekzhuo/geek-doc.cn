# ts-opensta-no-clock-startpoint

**对应教程**：https://geek-doc.cn/eda/ts-opensta-no-clock-startpoint.html

演示 OpenSTA 时序起点无时钟警告的三种 create_clock 漏约束场景：完全不建时钟、时钟建在错误对象上、SDC 时钟名与网表/后续引用不一致，以及修复后的 MET 复跑。

## 设计

两级寄存器小网表 `top.v`：`u_a`（DFF_P）→ `u_buf`（BUF_X1）→ `u_b`（DFF_P），时钟周期 1.0ns，寄存器间路径 data arrival 0.350ns，正确约束下 slack 0.550ns（MET）。

| 用例 | 约束写法 | 结果 |
|---|---|---|
| diag | 建时钟前后的对象清点 | 建前 all_clocks 计数 0、check_setup 报 2 个 unclocked register pins；建后时钟源为端口 clk |
| case1_noclock | 完全不写 create_clock | check_setup 报 2 unclocked pins / 3 unconstrained endpoints；report_checks 为 No paths found，-unconstrained 下 Path Group (none)、Path is unconstrained |
| case2_wrongobj | create_clock 建在内部 pin u_a/C | 源寄存器自称 clocked by clk，下游 u_b 仍无时钟；仍剩 1 unclocked pin，路径仍 unconstrained |
| case3_namemismatch | 时钟命名 sys_clk，后续引用 clk | get_clocks clk 报 clock not found；set_input_delay 失败；寄存器间路径仍按 sys_clk 分析（IO 约束丢失） |
| fixed | create_clock 建在输入端口 clk | check_setup 干净；Path Group: clk，slack 0.550ns（MET） |

## 复现

需要本机已安装 OpenSTA 2.0.17（或 Docker 镜像 geek-eda:0.3-sta）：

```bash
# 本机
bash run.sh

# Docker
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash run.sh
```

脚本合并 stdout/stderr 并打印每组退出码（五组均为 0，这本身就是要演示的陷阱之一）。
