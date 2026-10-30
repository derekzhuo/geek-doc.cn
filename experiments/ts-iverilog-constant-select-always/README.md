# iverilog always 块常量位选报错复现

**对应教程**：https://geek-doc.cn/eda/ts-iverilog-constant-select-always.html（教程上线后生效）

用 Icarus Verilog 13.0 复现 `wire` 的常量 part-select / bit-select 被 `always` 过程赋值时的报错，并验证改为 `reg` 后同一索引写法可以编译和运行。

## 文件

- `bad.v`：把 `wire [3:0] data` 放在过程赋值左值，预期编译失败。
- `fixed.v`：只把声明改为 `reg [3:0] data`，索引与赋值保持不变。
- `tb.v`：检查输入为 0 和 1 时输出是否跟随。
- `run.sh`：顺序执行失败复现与修复验证。

## 复现

```bash
sh run.sh
```

脚本预期先返回坏例编译失败，再输出修复例的 `PASS`。脚本整体退出码为 0 表示两种预期都满足。
