# nextpnr-ice40 顶层端口未在 PCF 约束

**对应教程**：https://geek-doc.cn/eda/ts-nextpnr-unconstrained-top-port.html（上线后生效）

## 复现方式

```bash
docker run --rm -v "$PWD":/work -w /work/ts-nextpnr-unconstrained-top-port geek-eda:0.4-flow bash run.sh
```

脚本按「原始报错 → 定位 → 修复后复跑」顺序打印每一步命令、完整输出与退出码，关键证据与教程中的终端实录一致。
