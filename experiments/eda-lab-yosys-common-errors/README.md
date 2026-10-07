# eda-lab-yosys-common-errors

yosys 0.33 四类常见报错的真实触发实验（配套 geek-doc.cn 文档「yosys 常见报错」）。

## 内容

| 文件 | 触发的错误 | yosys 0.33 实测行为 |
|---|---|---|
| `err_undeclared.v` | `default_nettype none` 下未声明线网 | read_verilog 给 Warning（implicitly declared），exit=0 |
| `err_multidriver.v` | 同一 reg 两个 always 块驱动 | proc 后 `check` 报 Warning: multiple conflicting drivers，exit=0 |
| `err_sv_syntax.v` | logic/always_ff 不加 `-sv` | read_verilog 报 `ERROR: syntax error, unexpected TOK_ID`，exit=1 |
| `err_combloop.v` | 组合逻辑环 | synth+check 报 `Warning: found logic loop`，exit=0（不挂死） |
| `ok_fixed.v` | 四类问题全部修复的对照 | synth + check 全过，0 problems |

## 运行

本机直接跑（需已装 yosys）：

```bash
make run
```

或在 geek-eda:0.1 容器里跑（与文档完全同环境）：

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v <本仓库 experiments 目录绝对路径>:/work \
  -w /work/eda-lab-yosys-common-errors geek-eda:0.1 bash -c 'make run'
```

所有报错原文落 `out/*.log`（每个 log 末尾附 `exit=` 退出码）。`make clean` 清空产物。
