#!/usr/bin/env bash
# run_regress.sh -- 仿真回归控制脚本模板（iverilog 版）
# 用法:
#   ./run_regress.sh                # 默认 5 个随机种子
#   SEED_LIST="1 7 13 42 99" ./run_regress.sh   # 指定种子清单
#   NSEED=20 ./run_regress.sh       # 随机生成 20 个种子
#   INJECT_FAIL=1 ./run_regress.sh  # 注入失败（演示失败汇总路径）

set -u                      # 引用未定义变量即报错；不用 set -e 的原因见正文
LOG_DIR="${LOG_DIR:-logs}"
mkdir -p "$LOG_DIR"

DUT="alu8.v"
TB="tb_alu8.v"
SIMV="$LOG_DIR/simv.out"

# ---- 1. 编译（编译失败直接退出，回归没有意义）----
EXTRA_DEF=""
if [ "${INJECT_FAIL:-0}" = "1" ]; then
    EXTRA_DEF="-DFAIL_INJECT"
fi
if ! iverilog -g2005 -o "$SIMV" $EXTRA_DEF "$DUT" "$TB"; then
    echo "[REGRESS] COMPILE FAIL, abort"
    exit 2
fi

# ---- 2. 生成种子清单 ----
if [ -n "${SEED_LIST:-}" ]; then
    seeds="$SEED_LIST"
else
    n="${NSEED:-5}"
    seeds=""
    i=0
    while [ "$i" -lt "$n" ]; do
        seeds="$seeds $((RANDOM * 32768 + RANDOM))"
        i=$((i + 1))
    done
fi

# ---- 3. 逐种子跑仿真，判定 PASS/FAIL ----
pass_list=""
fail_list=""
for s in $seeds; do
    log="$LOG_DIR/seed_${s}.log"
    vvp "$SIMV" +seed="$s" > "$log" 2>&1
    rc=$?
    if [ $rc -eq 0 ] && grep -q "TEST PASS" "$log" && ! grep -q "TEST FAIL" "$log"; then
        echo "[REGRESS] seed=$s PASS"
        pass_list="$pass_list $s"
    else
        echo "[REGRESS] seed=$s FAIL (rc=$rc, log=$log)"
        fail_list="$fail_list $s"
    fi
done

# ---- 4. 汇总与退出码 ----
np=$(echo $pass_list | wc -w | tr -d ' ')
nf=$(echo $fail_list | wc -w | tr -d ' ')
echo "[REGRESS] SUMMARY pass=$np fail=$nf"
if [ "$nf" -gt 0 ]; then
    echo "[REGRESS] FAILED SEEDS:$fail_list"
    exit 1
fi
echo "[REGRESS] ALL PASS"
exit 0
