#!/bin/bash
# 补拉 phase52 完整 + phase53
B="ssh -o BatchMode=yes root@10.206.0.2"
BDIR=/root/echo-day04/results_split_v2

echo "########## PHASE 52 完整: LT vs ET ##########"
$B "for m in lt et; do for c in 100 1000; do for mode in long short; do echo \"--- \$m c\$c \$mode ---\"; for i in 1 2 3; do f=$BDIR/52-\$m-c\$c-\$mode-r\$i.txt; [ -f \$f ] && grep -E '^ QPS|^  P50|^  P99' \$f | tr '\n' ' ' && echo ''; done; done; done; done" 2>&1

echo ""
echo "########## PHASE 53 完整: 连接数扫描 ##########"
$B "for c in 100 500 1000 2000 5000; do for mode in short long; do echo \"--- c\$c \$mode ---\"; for i in 1 2; do f=$BDIR/53-scan-c\$c-\$mode-r\$i.txt; [ -f \$f ] && grep -E '^ QPS|^  P50|^  P99' \$f | tr '\n' ' ' && echo ''; done; done; done" 2>&1
