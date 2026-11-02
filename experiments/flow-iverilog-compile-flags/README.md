# iverilog 编译选项实战实验

**对应教程**：https://geek-doc.cn/eda/flow-iverilog-compile-flags.html （上线后生效）

本目录用 Icarus Verilog 13.0 对六个常用编译选项做「加 / 不加」的真实对照：

| 文件 | 演示选项 | 对照内容 |
|---|---|---|
| `g2012_feat.v` | `-g2005` / `-g2012` | `logic`、`always_comb` 在 2005 下报错，在 2012 下通过 |
| `inc_demo.v` + `hdrs/defs.vh` | `-I` | 不带头文件搜索路径时 include 失败，`-Ihdrs` 后通过 |
| `macro_demo.v` | `-D` | 无宏时走 ifndef 分支，`-DDEBUG -DWIDTH=16` 后走条件分支 |
| `param_demo.v` | `-s` / `-P` | 默认参数 WIDTH=4，`-Ptb_par.WIDTH=12` 覆盖为 12 |
| `param_demo.v` | `-o` | 不传 `-o` 产物叫 `a.out`，传后可自定义产物名 |
| `warn_demo.v` / `bind_demo.v` | `-Wall` | 隐式线网、悬空输入端口默认不提示，`-Wall` 后给出告警 |

## 复现

```bash
make run
# 或
bash run.sh
```

脚本把生成的 `.vvp` 和 `a.out` 都放在 `.build/` 下，不污染源码目录；`make clean` 可清掉。

## 环境

- Icarus Verilog 13.0（`iverilog -V` 查看版本）
- 实测日期：2026-11-03，macOS 原生工具链（Linux 下行为一致）
