# Yosys defparam 层次参数覆盖复现

**对应教程**：https://geek-doc.cn/eda/ts-yosys-defparam-not-supported.html（上线后生效）

本实验对比两种 Verilog 参数覆盖写法：独立的 `defparam u_override.WIDTH = 8;`，以及实例参数列表 `child #(.WIDTH(8)) u_override (...)`。两个设计都保留一个使用默认参数的实例，并让 `OUT_WIDTH = WIDTH + 1` 参与端口位宽计算，用来检查覆盖值与派生位宽，而不只是观察命令是否退出成功。

## 文件

- `defparam.v`：defparam 层次覆盖版本。
- `fixed.v`：改为 `#()` 具名实例传参的版本。
- `check-json.mjs`：读取 Yosys JSON，检查两个实例的 `WIDTH`、派生模块端口位宽和顶层连接位宽。
- `run.sh`：依次运行两个版本并执行相同断言。
- `run1.log`：2026-10-30 使用 Docker 镜像 `geek-eda:0.2` 中 Yosys 0.33 的完整合并输出。

## 复现

需要 Docker 与 Node.js。在公开仓根目录运行：

```bash
bash experiments/ts-yosys-defparam-not-supported/run.sh
```

脚本通过 `read_verilog`、`hierarchy -check -top top`、`proc`、`opt_clean`、`check -assert` 和 `write_json` 处理设计；临时 JSON 在退出时自动删除。成功的末尾输出为：

```bash
PASS: defparam keeps default WIDTH=4 and applies override WIDTH=8; derived OUT_WIDTH=5/9
PASS: fixed keeps default WIDTH=4 and applies override WIDTH=8; derived OUT_WIDTH=5/9
ALL CHECKS PASS
```

Yosys 0.33 对本实验的简单 defparam 用法静默接受，没有发出 warning 或 error。该结果只证明本文两个具体设计的参数覆盖与派生位宽行为，不构成对其他层次写法或其他版本的形式等价结论。
