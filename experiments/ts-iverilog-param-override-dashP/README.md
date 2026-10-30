# iverilog -P 参数覆盖实验

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-param-override-dashP.html （上线后生效）

本目录用 Icarus Verilog 13.0 验证 `-P` 的完整层次参数路径、多个参数覆盖、`-s` 顶层选择，以及短参数名和错误实例路径的失败行为。

## 复现

```bash
bash run.sh
```

`params.v` 包含 `tb` 与 `tb_alt` 两个测试顶层，以及 `dut.u_leaf` 两层实例。脚本生成的 `.vvp` 文件放在 `.build/`，不会改动源码。
