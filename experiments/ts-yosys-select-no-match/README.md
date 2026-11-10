# Yosys select 匹配不到对象的空选择集问题

**对应教程**：https://geek-doc.cn/eda/ts-yosys-select-no-match.html（上线后生效）

## 复现方式

```bash
docker run --rm -v "$PWD":/work -w /work/ts-yosys-select-no-match geek-eda:0.2 bash run.sh
```

脚本按「原始报错 → 定位 → 修复后复跑」顺序打印每一步命令、完整输出与退出码，关键证据与教程中的终端实录一致。
