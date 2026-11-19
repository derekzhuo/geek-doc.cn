# klayout-gds-read-fail

**对应教程**：https://geek-doc.cn/eda/ts-klayout-gds-read-fail.html

复现 KLayout 读取版图流文件时的三类失败：截断的 GDS2 流（`Unexpected end-of-file`）、文本文件伪装成 GDS（`Stream has unknown format`），并给出健康 GDS 读取与 OASIS 格式往返两个通过对照。

## 文件

- `make_gds.rb`：生成最小合法 GDS2（一个 TOP 单元、layer 1/0 上一个矩形，dbu 1 nm）。
- `read_gds.rb`：通用读取脚本，读入成功打印单元名与图形数，解析失败非零退出。
- `to_oasis.rb`：GDS2 → OASIS 写出并回读，验证格式往返不丢图形。
- `run.sh`：合并 stdout/stderr，顺序跑五组并记录每组退出码。

## 复现方式

使用 Docker 镜像 `geek-eda:0.5-asic`（Ubuntu 24.04，KLayout 0.28.16）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

本机已装 KLayout 0.28 时也可直接 `bash run.sh`。
