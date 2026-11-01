# ts-opensta-liberty-not-found

**对应教程**：https://geek-doc.cn/eda/ts-opensta-liberty-not-found.html （上线后生效）

复现 OpenSTA `read_liberty` 报「库文件找不到 / 读不进」的两类故障：路径错误（相对路径、未设置环境变量）与文件内容/格式错误（截断的 Liberty、把 Verilog 当成库、直接喂 `.lib.gz`、corner 名未定义），并附一份可正常链接的最小库作为对照。

## 文件

- `missing.tcl`：相对路径文件不存在、环境变量 `STA_LIB` 未设置两种路径事故。
- `broken.tcl`：四种格式事故——截断库、Verilog 网表、gzip 压缩库、未定义 corner 名。
- `valid.tcl`：读入合法库、读网表、链接、建时钟并出时序报告的通过组。
- `minimal.lib`：含阈值定义的最小教学库（DFF_P / BUF_X1）。
- `broken.lib`：故意在第 7 行截断的库。
- `top.v`：DFF + BUF 最小网表。
- `run.sh`：合并 stdout/stderr，顺序跑三组并记录退出码。

## 复现方式

使用 Docker 镜像 `geek-eda:0.3-sta`（Ubuntu 24.04，OpenSTA 2.0.17）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.3-sta bash -lc 'bash run.sh'
```

本机已安装 OpenSTA 2.0.17 时也可直接 `bash run.sh`。
