---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/c-beginner-practice/`，配套页面 https://geek-doc.cn/demos/c-beginner-practice/


# c-beginner-practice：C 入门综合练习代码

本目录收录 `languages/c/beginner/` 综合练习（72-77）的完整可运行代码。

| 文件 | 对应文档 | 运行 |
|------|----------|------|
| `guess_number.c` | [72-practice-guess-number.md](/languages/c/beginner/72-practice-guess-number.md) | `make run-guess` |
| `calculator.c` | [73-practice-calculator.md](/languages/c/beginner/73-practice-calculator.md) | `make run-calc ARGS="10 + 3.5"` |
| `student_mgmt.c` | [74-practice-student-mgmt.md](/languages/c/beginner/74-practice-student-mgmt.md) | `make run-student` |
| `linked_list.c` | [75-practice-linked-list.md](/languages/c/beginner/75-practice-linked-list.md) | `make run-list` |
| `text_stats.c` | [76-practice-text-stats.md](/languages/c/beginner/76-practice-text-stats.md) | `make run-stats FILE=sample.txt` |
| `sorting.c` | [77-practice-sorting.md](/languages/c/beginner/77-practice-sorting.md) | `make run-sort` |

## 编译与运行

```bash
make            # 编译全部（-O0 -g，与本站演示约定一致）
make run-guess  # 猜数字（交互式）
```

## 实测输出（Linux, gcc）

```
$ make
gcc -O0 -g guess_number.c -o guess_number
gcc -O0 -g calculator.c -o calculator
gcc -O0 -g student_mgmt.c -o student_mgmt
gcc -O0 -g linked_list.c -o linked_list
gcc -O0 -g text_stats.c -o text_stats
gcc -O0 -g sorting.c -o sorting

$ ./sorting
bubble:   1 2 3 5 8 9
selection:1 2 3 5 8 9
insertion:1 2 3 5 8 9
qsort:    1 2 3 5 8 9

$ ./linked_list
20 10 30
20 30

$ ./calculator 10 + 3.5
10 + 3.5 = 13.5
$ ./calculator 5 / 0
错误：不能除以零
$ ./calculator 2 x 3
错误：不支持的运算符 x

$ printf 'hello world\nc language\n' > sample.txt
$ ./text_stats sample.txt
2 行, 4 单词, 24 字符
$ wc sample.txt
 2  4 24 sample.txt
```

## 一句话总结

本目录是 C 入门综合练习（猜数字、计算器、学生管理、链表、文本统计、排序）的完整可运行代码，配合 `languages/c/beginner/` 72–77 篇文档，`make` 加对应目标即可运行。
