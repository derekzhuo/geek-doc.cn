#!/usr/bin/env bash
# mock 用例：模拟一个出现失配的 testbench，打印 TEST FAIL 并非零退出
set -u
seed="${SEED:-1}"
echo "mock simulator start, seed=$seed"
echo "vector 17 expected 0x00000000 got 0x00000001"
echo "TEST FAIL seed=$seed mismatches=1"
exit 1
