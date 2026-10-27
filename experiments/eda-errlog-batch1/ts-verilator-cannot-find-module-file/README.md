# ts-verilator-cannot-find-module-file

复现 Verilator `%Error: Could not find the file containing module ...` /
`Cannot find file containing module: sub_adder`。

## 复现

```bash
bash run.sh
```

- `logs/err-missing-file.log`：命令行只给顶层，子模块文件没列上。
- `logs/err-bad-incdir.log`：`-I` 指向不存在的目录，include/模块搜不到。
- `logs/fix-list-all.log`：把顶层和全部子模块文件一起列出后通过。

注意 Verilator 不会递归自动发现源文件：要么命令行列全，要么用
`-I<dir>` 配合模块同名文件，工程化做法是 `$(find rtl -name '*.v')`。

## 环境

Verilator ≥ 4.0。

## 原始证据

本目录 `evidence/`（原始日志，与教程内嵌摘录同源）
