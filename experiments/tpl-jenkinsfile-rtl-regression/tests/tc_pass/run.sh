#!/usr/bin/env bash
# mock 用例：模拟一个自校验 testbench，全向量一致时打印 TEST PASS
set -u
seed="${SEED:-1}"
echo "mock simulator start, seed=$seed"
echo "checked 50 vectors, 0 mismatch"
echo "TEST PASS seed=$seed"
exit 0
