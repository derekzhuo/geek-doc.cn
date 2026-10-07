# eda-lab-iverilog-common-errors

故意触发 Icarus Verilog（iverilog）4 类最常见报错的最小用例集，配套 geek-doc.cn 文档
《iverilog 常见报错：语法错误、未声明、端口连接与未知模块排查》。

## 环境

Docker 容器 `geek-eda:0.1`（Icarus Verilog 12.0 stable）：

```bash
docker run --rm --user $(id -u):$(id -g) -e HOME=/tmp \
  -v ~/Project/geek-doc.cn/experiments:/work \
  -w /work/eda-lab-iverilog-common-errors geek-eda:0.1 bash -c 'make run'
```

## 用例

| 文件 | 触发的错误 |
|---|---|
| `err_syntax_semicolon.v` | 语法错误（always 内漏分号） |
| `err_undeclared.v` | 未声明标识符 |
| `err_port.v` | 端口位宽不匹配（-Wall 告警） |
| `err_unknown_module.v` | 实例化未知模块（unknown module type） |

每条编译命令预期失败，报错原文落在 `out/*.log`（Makefile 用 `-` 前缀忽略失败继续跑）。
