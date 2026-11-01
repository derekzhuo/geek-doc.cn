# ts-opensta-false-path-no-match

**对应教程**：https://geek-doc.cn/eda/ts-opensta-false-path-no-match.html （上线后生效）

演示 OpenSTA 中 `set_false_path` 的对象选择器匹配不到 pin 时的“假豁免”现象：约束命令失败、时序路径仍被分析。

## 设计

两级层次小网表 `top.v`：`u_a`（DFF_P）→ `u_buf`（BUF_X1）→ `u_b`（DFF_P），时钟周期 0.4ns，寄存器间路径 arrival 0.500ns、slack -0.200ns（VIOLATED）。

三组对照：

| 用例 | SDC 写法 | 结果 |
|---|---|---|
| bad | `get_pins u_b.D`（点号当层次分隔符） | Warning + set_false_path 失败，路径仍报 -0.200 VIOLATED |
| warn_empty | `get_pins {u_b./D}`（正则元字符 `.` 但没加 -regexp） | 计数为 0，命令失败，路径仍报 -0.200 VIOLATED |
| fixed | `get_pins u_b/D`（斜杠层次路径） | 计数为 1，路径从时序报告消失（No paths found） |

## 复现

需要本机已安装 OpenSTA 2.0.17（或 Docker 镜像 geek-eda:0.3-sta）：

```bash
# 本机
bash run.sh

# Docker
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash run.sh
```

脚本合并 stdout/stderr 并打印每组退出码（三组均为 0，这本身就是要演示的陷阱之一）。
