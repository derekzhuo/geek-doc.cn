# Yosys 逻辑等价检查（LEC）：RTL vs 综合网表（lec-yosys-equiv-opt）

**对应教程**：https://geek-doc.cn/chip-design/intermediate/lec-yosys-equiv-opt.html（上线后生效）

用 yosys `equiv_make / equiv_simple / equiv_status` 做逻辑等价检查：RTL vs 综合网表证等价（PASS），RTL vs 故意写错的版本（sub 写成 a-b-1）逐位抓出不等价点（FAIL）。一正一反双份证据。

## 文件

- `simple_alu.v` —— 正确版 8-bit ALU
- `simple_alu_bad.v` —— 故意错版：sub 写成 `a-b-1`
- `mknet.ys` —— 把正确 RTL 综合成门级网表 alu_net.v
- `lec_pass.ys` —— RTL vs 网表等价检查脚本
- `lec_fail.ys` —— RTL vs 错版等价检查脚本
- `output/mknet.log` / `output/pass.log` / `output/fail.log` —— 三份实测日志

## 实验环境

- Ubuntu 22.04 + Yosys 0.9

## 复现

```bash
yosys mknet.ys      # 产 alu_net.v
yosys lec_pass.ys   # read gold → prep/proc → rename → read gate → equiv_make → equiv_simple → equiv_status
yosys lec_fail.ys
```

两个坑（脚本里已体现）：gold 侧必须先 `proc/prep`（否则报「Gold module contains memories or processes」）；fail 版两次 read 之间不能再 `prep -top`（会删掉已 rename 的 gold），改按模块逐个 `proc/opt`。

## 关键结果

- PASS 侧：`Found 9 $equiv cells, 9 proven 0 unproven. Equivalence successfully proven!`
- FAIL 侧：`Found 9 unproven $equiv cells`，逐位列出 `y[7:0]`、`zero` 不等价点
