#!/bin/bash
# bench.sh — 100 并发 nc 压测脚本
#
# 用法：
#   ./bench.sh                        # 默认 100 并发, 127.0.0.1:9988
#   ./bench.sh 192.168.1.10 9988 200  # 指定 IP/端口/并发数

IP="${1:-127.0.0.1}"
PORT="${2:-9988}"
CONCUR="${3:-100}"

echo "=== Echo Server Benchmark ==="
echo "Target:   ${IP}:${PORT}"
echo "Concurrency: ${CONCUR}"
echo "============================="

START=$(date +%s%N)

for i in $(seq 1 $CONCUR); do
    echo "hello $i" | nc -w 3 "${IP}" "${PORT}" > /dev/null 2>&1 &
done

# 等待所有后台进程完成
wait

END=$(date +%s%N)
ELAPSED=$(( (END - START) / 1000000 ))  # ms -> actual μs display handled below

SUCCESS=0
FAIL=0

# 验证：逐一检查每个连接是否成功（再次遍历，nc 已全部退出）
for i in $(seq 1 $CONCUR); do
    result=$(echo "ping $i" | nc -w 2 "${IP}" "${PORT}" 2>/dev/null)
    if [ -n "$result" ]; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
done

# 简化版：直接用第一次 wait 后的时间算 QPS
# 验证方式改为用 echo-bench C 程序更准确
# 这里只做粗略的并发 fire-and-forget 测试

echo ""
echo "========== Results =========="
echo "Total requests:   ${CONCUR}"
echo "Elapsed:          ${ELAPSED} ms"
echo "QPS (approx):     $(( CONCUR * 1000 / (ELAPSED > 0 ? ELAPSED : 1) ))"

# 更准确的 QPS：用纳秒
ELAPSED_US=$(( (END - START) / 1000 ))
if [ "$ELAPSED_US" -gt 0 ]; then
    QPS=$(( CONCUR * 1000000 / ELAPSED_US ))
    echo "QPS (precise):    ${QPS} req/s"
fi

echo "============================="
