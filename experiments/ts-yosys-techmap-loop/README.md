# ts-yosys-techmap-loop

**对应教程**：https://geek-doc.cn/eda/ts-yosys-techmap-loop.html（上线后生效）

Yosys 0.33 自定义 `techmap` 模板自引用的最小复现，以及把 `$not` 显式替换为门级 `$_NOT_` 后的收敛对照。

## 文件

- `top.v`：只含一个 `$not` 单元的顶层。
- `loop_bad.v`：`$not` 模板再次实例化参数化 `$not`，形成自引用。
- `loop_fixed.v`：模板显式实例化 `$_NOT_`，不再产生映射目标 `$not`。
- `run.sh`：坏例限制 256 MB 地址空间和 3 秒运行时间；修复例运行 `techmap/stat/check`。
- `run1.log`：本次真实运行的合并输出，含三次元数据头、超时退出码、网表统计与最终结果。

## 复现

本机已安装 Yosys 和 GNU `timeout` 时：

```bash
bash run.sh
```

使用本文相同容器版本时，在本目录执行：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

本次坏例由 3 秒强制超时终止，退出码 137；修复例得到 1 个 `$_NOT_`、`check` 为 0 问题并退出 0。该对照只证明映射能够收敛及网表结构检查通过，未做功能仿真或形式等价证明。

测试环境：Yosys 0.33 (git sha1 2584903a060)，`geek-eda:0.2` Docker 镜像。
