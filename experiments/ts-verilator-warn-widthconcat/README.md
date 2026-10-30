# Verilator WIDTHCONCAT 最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-widthconcat.html（上线后生效）

四个 SystemVerilog 用例分别展示赋值与端口连接中的拼接位宽告警，以及显式补位、拆分中间信号两种修复。

在已安装 Verilator 5.020 的 Linux 环境运行：

```bash
bash run.sh
```

也可使用教程相同的容器镜像，在本目录运行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

脚本预期两个 bad 用例报 `%Warning-WIDTHCONCAT`，两个 fixed 用例零告警、退出码为 0，最后输出 `PASS`。
