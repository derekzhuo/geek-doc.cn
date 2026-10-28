---
updated: 2026-10-22
---

> **源码镜像说明**：本目录镜像自 geek-doc.cn 文档站实验目录 `/demos/cpp-beginner-practice/`，配套页面 https://geek-doc.cn/demos/cpp-beginner-practice/


# cpp-beginner-practice：C++ 入门综合练习代码

本目录收录 `languages/cpp/beginner/` 综合练习（58-63）的完整可运行代码。

| 文件 | 对应文档 | 运行 |
|------|----------|------|
| `book_mgmt.cpp` | [58-practice-book-mgmt.md](/languages/cpp/beginner/58-practice-book-mgmt.md) | `make run-book` |
| `grade_system.cpp` | [59-practice-grade-system.md](/languages/cpp/beginner/59-practice-grade-system.md) | `make run-grade` |
| `calculator.cpp` | [60-practice-calculator.md](/languages/cpp/beginner/60-practice-calculator.md) | `make run-calc` |
| `word_count.cpp` | [61-practice-word-count.md](/languages/cpp/beginner/61-practice-word-count.md) | `make run-stats FILE=sample.txt` |
| `linked_list.cpp` | [62-practice-linked-list.md](/languages/cpp/beginner/62-practice-linked-list.md) | `make run-list` |
| `cli_tool.cpp` | [63-practice-cli-tool.md](/languages/cpp/beginner/63-practice-cli-tool.md) | `make run-cli ARGS="-v a.txt b.txt"` |

## 编译与运行

```bash
make             # 编译全部（-O0 -g -std=c++17，与本站演示约定一致）
make run-book    # 图书管理系统（交互式）
make run-calc    # 计算器（交互式，输入如 "3 + 4 * 2"）
make run-stats FILE=sample.txt   # 单词统计
make run-cli ARGS="--count 3 data.txt"
```

## 实测输出（Linux, g++）

```bash
$ make
g++ -O0 -g -Wall -Wextra -std=c++17 book_mgmt.cpp -o book_mgmt
g++ -O0 -g -Wall -Wextra -std=c++17 grade_system.cpp -o grade_system
g++ -O0 -g -Wall -Wextra -std=c++17 calculator.cpp -o calculator
g++ -O0 -g -Wall -Wextra -std=c++17 word_count.cpp -o word_count
g++ -O0 -g -Wall -Wextra -std=c++17 linked_list.cpp -o linked_list
g++ -O0 -g -Wall -Wextra -std=c++17 cli_tool.cpp -o cli_tool

$ ./linked_list
=== push_front 1 2 3 ===
3 -> 2 -> 1 -> null
=== push_back 4 5 ===
3 -> 2 -> 1 -> 4 -> 5 -> null
=== find(2) ===
找到: 2
=== find(99) ===
未找到: 99
=== size ===
5
=== 压测：插入 100000 个节点后析构 ===
链表大小: 100000
链表销毁完成，无崩溃

$ echo "3 + 4 * 2" | ./calculator
输入中缀表达式（空格分隔，如: 3 + 4 * 2）: 结果: 11

$ ./word_count sample.txt 5
总词数（去重）: 16
1. the (4 次)
2. fox (3 次)
3. dog (3 次)
4. brown (2 次)
5. lazy (2 次)

$ ./cli_tool -v a.txt b.txt
[verbose] 解析完成
处理 a.txt x1
处理 b.txt x1
$ ./cli_tool --count 3 data.txt
处理 data.txt x3
$ ./cli_tool --unknown foo.txt
错误: 未知选项 --unknown
```

注：`book_mgmt`、`grade_system`、`calculator` 为交互式程序，以上仅列出无交互输出部分；完整交互输出见对应文档的"实验数据"小节。

## 一句话总结

本目录是 C++ 入门综合练习（图书管理、成绩系统、计算器、单词统计、链表、CLI 工具）的完整可运行代码，配合 `languages/cpp/beginner/` 58–63 篇文档，按 `make run-*` 目标运行。
