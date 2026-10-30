# Yosys generate 作用域名称对照实验

**对应教程**：https://geek-doc.cn/eda/ts-yosys-generate-scope-name.html（上线后生效）

`auto.v` 使用未命名的条件 generate 块，`named.v` 只增加显式标签 `decode_scope`。运行脚本用 Yosys 0.33 输出内部线网和单元名称，检查生成网表中的作用域前缀，统计告警，并对两个版本执行完整综合。

## 运行

```bash
bash run.sh
```

脚本需要 Docker 和本地镜像 `geek-eda:0.2`。临时日志与网表写入临时目录，退出时自动清理；终端输出可作为实验记录保存。
