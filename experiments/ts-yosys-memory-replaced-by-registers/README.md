# Yosys memory_map 展开对照实验

**对应教程**：https://geek-doc.cn/eda/ts-yosys-memory-replaced-by-registers.html （上线后生效）

`async_read.v` 与 `sync_read.v` 都是 64×16 位、同步写的数组；区别只在读口。`run.sh` 在 `memory_dff`、`memory_collect`、`memory_map` 后各执行一次 `stat`，用来区分「已收集成 memory cell」与「后续被展开成触发器和多路选择器」。

## 复现

已安装 Yosys 0.33 时，在本目录运行：

```bash
bash run.sh
```

也可使用教程同版本镜像：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.2 bash run.sh
```

`run1.log` 是镜像内 Yosys 0.33 的完整 stdout/stderr 实录，末尾 `PASS` 表示两次综合命令均正常退出。这里只比较中间网表 cell 构成，没有进行工艺映射或面积测量。
