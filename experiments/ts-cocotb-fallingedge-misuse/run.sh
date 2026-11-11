#!/usr/bin/env bash
# 逐个复现 cocotb 边沿触发器误用场景。
# 每个用例都由外部 timeout 30 兜底，保证即使协程永久挂起，
# 整条脚本也会继续执行，并记录退出码（挂死被杀为 124）。
set -u
cd "$(dirname "$0")"

run_case() {
    name=$1
    echo "==================== CASE: ${name} ===================="
    (
        cd "cases/${name}" || exit 99
        timeout --signal=TERM 30 make SIM=icarus
    ) 2>&1
    echo "${name}_EXIT=$?"
    echo ""
}

run_case c1-reset-polarity
run_case c2-clock-not-started
run_case c2b-no-events
run_case c3-comb-edge
run_case c4-timer-vs-edge
run_case c5-skipping
run_case good

echo "==================== SUMMARY ===================="
for d in cases/*/; do
    name=$(basename "$d")
    if [ -f "$d/results.xml" ]; then
        echo "$name results.xml: $(grep -o '<testsuite name="[^>]*>' "$d/results.xml" | head -1 | sed -E 's/ timestamp="[^"]*"//; s/ hostname="[^"]*"//')"
    else
        echo "$name results.xml: absent (simulation did not run or was killed)"
    fi
done
