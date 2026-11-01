# ts-opensta-input-delay-no-clock

**对应教程**：https://geek-doc.cn/eda/ts-opensta-input-delay-no-clock.html （上线后生效）

OpenSTA `set_input_delay -clock` 引用未定义时钟的最小复现实验：忘建时钟、时钟名拼错/写成层次名、时钟建在错误端口三种触发，外加修复组。

## 复现

需要 Docker 镜像 `geek-eda:0.3-sta`（Ubuntu 24.04 + OpenSTA 2.0.17）：

```bash
bash run.sh
```

或本机已装 OpenSTA 时：`STA_BIN=sta bash run.sh`。

## 文件

- `top.v` / `experiment.lib`：含一个 DFF 与输出 BUF 的最小设计和教学时序库。
- `no_clock.sdc`：完全不建时钟，直接引用 `-clock clk`。
- `typo_hier.sdc`：时钟命名为 `clck`，却引用 `clk` 与层次名 `top/clk`。
- `wrong_port.sdc`：把名为 `clk` 的时钟建在数据端口 `d` 上。
- `fixed.sdc`：时钟建在真实时钟端口 `clk`，输入/输出延迟正常。
- 各 `*.tcl`：读库、读设计、应用 SDC、`check_setup -verbose`、`report_checks`。
