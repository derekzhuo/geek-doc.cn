# Yosys iCE40 SB_IO 推断与显式例化对照

**对应教程**：https://geek-doc.cn/eda/ts-yosys-ice40-sb-io-inference.html（上线后生效）

本目录包含 Yosys 0.33 的五组真实综合对照：顶层双向口、内部三态、显式 `SB_IO`、低有效输出使能，以及 `tribuf -logic` 的内部三态转换。

## 文件

- `top_inferred.v`：高有效使能的顶层 `inout` 自动推断写法。
- `internal_tristate.v`：内部三态总线，后接反相逻辑。
- `top_explicit.v`：显式例化组合双向 `SB_IO`。
- `top_active_low.v`：低有效 `oe_n` 的顶层双向口。
- `run.sh`：按顺序执行五条命令，并记录每条命令的退出码。
- `run1.log`：`geek-eda:0.2` 容器内的原始合并输出。

## 复现

安装 Docker 后，在本目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash ./run.sh
```

也可在已安装 Yosys 0.33 的 Linux 环境直接执行 `bash ./run.sh`。脚本中的五条 Yosys 命令本次退出码均为 0。结果只覆盖综合网表的 `stat` 与 `check`，不包含 nextpnr、引脚约束、时序分析或硬件验证。
