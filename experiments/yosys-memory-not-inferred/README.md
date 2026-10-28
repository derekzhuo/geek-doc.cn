# yosys-memory-not-inferred

**对应教程**：https://geek-doc.cn/eda/ts-yosys-memory-not-inferred.html

Yosys 综合时 memory 未被推断成 `$mem` cell 的对照实验：反例（组合块里异步写数组）展开成 6 万+ 个 `$eq`/`$dlatch`，正例（标准同步 RAM 模板）正常推断出 1 个 `$mem_v2`。

## 文件

- `ram_bad.v` —— 反例：`always @(*)` 里用阻塞赋值异步写 `mem[waddr]`，无时钟沿。
- `ram_good.v` —— 正例：标准同步 RAM 模板，写与读都在 `always @(posedge clk)` 里。

## 复现

```bash
# 反例：stat 里 Number of cells 爆炸到 6 万+，没有 $mem cell
yosys -Q -T -p 'read_verilog ram_bad.v; proc; memory_collect; stat'

# 正例：stat 里出现 $mem_v2 1 个，cell 总数个位数
yosys -Q -T -p 'read_verilog ram_good.v; proc; memory_collect; stat'
```

实测环境：Yosys 0.33（geek-eda:0.2 docker 镜像），2026-10-29。
