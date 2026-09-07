#!/bin/bash
# 汇总新环境全部实验结果（phase51/52/53/54 + PPS）
B="ssh -o BatchMode=yes root@10.206.0.2"
BDIR=/root/echo-day04/results_split_v2
ADIR=/root/echo-day04/results_split_v2

echo "########## PHASE 51: 线程数扩展 (LT 长连接 1000连接×1000轮×3) ##########"
$B "for n in 1 2 4 8 16 32; do echo \"--- t\$n ---\"; for i in 1 2 3; do f=$BDIR/51-t\$n-r\$i.txt; [ -f \$f ] && grep -E '^ QPS|^  P50|^  P99' \$f | tr '\n' ' ' && echo ''; done; done"

echo ""
echo "########## PHASE 52: LT vs ET (8线程 × {lt,et} × {long,short} × {100,1000}×3) ##########"
$B "for m in lt et; do for c in 100 1000; do for mode in long short; do echo \"--- \$m c\$c \$mode ---\"; for i in 1 2 3; do f=$BDIR/52-\$m-c\$c-\$mode-r\$i.txt; [ -f \$f ] && grep -E '^ QPS|^  P50|^  P99' \$f | tr '\n' ' ' && echo ''; done; done; done; done"

echo ""
echo "########## PHASE 53: 连接数扫描 (8线程 LT × {short,long} × {100,500,1000,2000,5000}×2) ##########"
$B "for c in 100 500 1000 2000 5000; do for mode in short long; do echo \"--- c\$c \$mode ---\"; for i in 1 2; do f=$BDIR/53-scan-c\$c-\$mode-r\$i.txt; [ -f \$f ] && grep -E '^ QPS|^  P50|^  P99' \$f | tr '\n' ' ' && echo ''; done; done; done"

echo ""
echo "########## PHASE 54: CPU 利用率 ##########"
echo "--- 服务端A pidstat (echo-mt-server) ---"
for n in 1 4 8 16; do
  echo "--- t$n ---"
  grep Average $ADIR/cpu-t$n.txt
done
echo "--- 客户端B mpstat (all) ---"
$B "for n in 1 4 8 16; do echo \"--- t\$n ---\"; grep 'Average.*all' $BDIR/mp-t\$n.txt; done"

echo ""
echo "########## PPS 长连接对照 (pps-long-c1000) ##########"
echo "--- B端 bench ---"
$B "grep -E '^ QPS|^  P50|^  P99' $BDIR/ppsbench-pps-long-c1000.txt"
echo "--- A端 PPS ---"
awk '/eth0/{print $3, $5}' $ADIR/pps-pps-long-c1000.txt
echo "--- A端 TW/SYN/EST ---"
cat $ADIR/tw-pps-long-c1000.txt

echo ""
echo "########## PPS 短连接雪崩 (short-c1000) ##########"
echo "--- B端 bench ---"
$B "grep -E '^ QPS|^  P50|^  P99|^  P999' $BDIR/ppsbench-short-c1000.txt"
echo "--- A端 PPS ---"
awk '/eth0/{print $3, $5}' $ADIR/pps-short-c1000.txt
echo "--- A端 TW/SYN/EST ---"
cat $ADIR/tw-short-c1000.txt
