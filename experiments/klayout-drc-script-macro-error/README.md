# klayout-drc-script-macro-error

**对应教程**：https://geek-doc.cn/eda/ts-klayout-drc-script-macro-error.html

复现 KLayout 批处理模式（`klayout -b -r`）执行 DRC deck 时的两类硬失败：Ruby 语法错误（`SyntaxError`，缺右括号）与未定义方法（`NoMethodError`，把 `width` 拼写成 `wdith`），并附一份合法 deck 出报告数据库的通过对照；另含一个静默坑探针——引用版图中不存在的 layer 99/0 时退出码仍为 0，只产出空报告。

## 文件

- `make_gds.rb`：生成最小输入 GDS2（TOP 单元，layer 1/0 一个 1µm × 2µm 矩形）。
- `drc_bad_syntax.drc`：`report(` 缺右括号，解析期 SyntaxError。
- `drc_bad_method.drc`：`wdith` 拼写错误，执行期 NoMethodError。
- `drc_empty_layer.drc`：引用不存在的 99/0 层，合法但零结果的静默对照。
- `drc_good.drc`：合法宽度检查，写出 `.lyrdb` 报告数据库。
- `run.sh`：合并 stdout/stderr，顺序跑五组并记录退出码与产物清单。

## 复现方式

使用 Docker 镜像 `geek-eda:0.5-asic`（Ubuntu 24.04，KLayout 0.28.16）：

```bash
docker run --rm -v "$PWD":/work -w /work geek-eda:0.5-asic bash -lc 'bash run.sh'
```

本机已装 KLayout 0.28 时也可直接 `bash run.sh`。
