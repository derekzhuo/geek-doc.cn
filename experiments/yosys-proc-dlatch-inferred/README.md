# yosys-proc-dlatch-inferred

**对应教程**：https://geek-doc.cn/eda/ts-yosys-proc-dlatch-inferred.html（上线后生效）

Yosys `proc` 阶段 `proc_dlatch` 推断出锁存器（"Latch inferred" / 网表中出现 `$dlatch`）的最小复现与修复对照。

## 文件

- `dlatch_bad.v` — 坏例子：`always @(*)` 里 `if` 没有 `else`，en 为 0 时 q 无赋值，proc_dlatch 推断出锁存器
- `dlatch_fixed.v` — 修复版：补全 else 分支，每个路径都有赋值，只剩一个 `$mux`

## 复现

```bash
yosys -p 'read_verilog dlatch_bad.v; hierarchy -top dlatch_bad; proc; stat'
# 日志出现：Latch inferred for signal `\dlatch_bad.\q' ...
# stat 的 cells 里出现 $dlatch

yosys -p 'read_verilog dlatch_fixed.v; hierarchy -top dlatch_fixed; proc; stat'
# 日志出现：No latch inferred ...
# stat 的 cells 里只有 $mux
```

测试环境：Yosys 0.33（geek-eda:0.2 docker 镜像）。
