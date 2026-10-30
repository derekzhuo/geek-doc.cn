# Verilator WAITCONST 常量等待最小复现

**对应教程**：https://geek-doc.cn/eda/ts-verilator-warn-waitconst.html（上线后生效）

`waitconst_bad.sv` 与 `waitconst_false.sv` 分别用 `wait (1'b1)` 和 `wait (1'b0)` 对比常真、常假语义；前者触发 WAITCONST，后者在本版本静默通过。`waitconst_fixed.sv` 改为等待会变化的 `start`、`done` 条件。

在已安装 Verilator 5.020 的 Linux 环境运行：

```bash
bash run.sh
```

也可使用本教程一致的容器环境：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

预期常真版本触发 WAITCONST 并以退出码 1 结束；常假版本在 Verilator 5.020 上不产生该告警，修复版以退出码 0 通过，脚本末尾输出 PASS。
