#!/usr/bin/env bash
# run_seeds.sh -- cocotb random-seed regression sweep.
# Each seed gets a fresh sim_build and its own log; the script always
# runs the full list before reporting, and exits non-zero on any failure.
set -u

SEEDS="${SEEDS:-1 2 7}"
DUT_FILE="${DUT_FILE:-sat_add8.v}"
LOG_DIR="${LOG_DIR:-logs}"
mkdir -p "$LOG_DIR"

pass_list=""
fail_list=""

for s in $SEEDS; do
    log="$LOG_DIR/seed_${s}.log"
    make clean >/dev/null 2>&1 || true
    make sim DUT_FILE="$DUT_FILE" COCOTB_RANDOM_SEED="$s" >"$log" 2>&1
    rc=$?
    if [ "$rc" -eq 0 ] && grep -q "TESTS=1 PASS=1 FAIL=0" "$log"; then
        echo "[REGRESS] seed=$s PASS"
        pass_list="$pass_list $s"
    else
        mm=$(grep -o "mismatches=[0-9]*" "$log" | tail -1)
        echo "[REGRESS] seed=$s FAIL (rc=$rc, $mm, log=$log)"
        fail_list="$fail_list $s"
    fi
done

np=$(echo $pass_list | wc -w | tr -d ' ')
nf=$(echo $fail_list | wc -w | tr -d ' ')
echo "[REGRESS] SUMMARY pass=$np fail=$nf"
if [ "$nf" -gt 0 ]; then
    echo "[REGRESS] FAILED SEEDS:$fail_list"
    exit 1
fi
echo "[REGRESS] ALL PASS"
exit 0
