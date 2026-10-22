#!/usr/bin/env bash
# 练习代码验证脚本：在 Linux 上编译运行，输出文档引用的实测数据
# 注意：calculator 除零等用例返回非零，故不启用 set -e
cd "$(dirname "$0")"

gcc -O0 -g -Wall -Wextra -std=gnu99 guess_number.c -o guess_number
gcc -O0 -g -Wall -Wextra -std=gnu99 calculator.c -o calculator
gcc -O0 -g -Wall -Wextra -std=gnu99 student_mgmt.c -o student_mgmt
gcc -O0 -g -Wall -Wextra -std=gnu99 linked_list.c -o linked_list
gcc -O0 -g -Wall -Wextra -std=gnu99 text_stats.c -o text_stats
gcc -O0 -g -Wall -Wextra -std=gnu99 sorting.c -o sorting

echo "=== sorting ==="
./sorting

echo "=== linked_list ==="
./linked_list

echo "=== calculator 10 + 3.5 ==="
./calculator 10 + 3.5
echo "=== calculator 5 / 0 ==="
./calculator 5 / 0
echo "=== calculator 2 x 3 ==="
./calculator 2 x 3

echo "=== text_stats sample.txt ==="
printf 'hello world\nc language\n' > sample.txt
./text_stats sample.txt
echo "--- wc 对照 ---"
wc sample.txt

echo "=== student_mgmt 菜单（交互冒烟） ==="
printf '1\n1001 alice 92.5\n1\n1002 bob 88.0\n2\n5\n0\n' | ./student_mgmt
echo "--- students.txt 内容 ---"
cat students.txt

echo "=== guess_number（交互冒烟：固定输入流） ==="
printf '50\nabc\n75\n82\n' | ./guess_number
