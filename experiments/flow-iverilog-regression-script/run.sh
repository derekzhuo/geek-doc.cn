#!/usr/bin/env bash
# run.sh -- 最小可复用回归脚本：遍历 tests/ 下每个用例，
#           逐例 iverilog 编译 -> vvp 运行 -> 退出码/PASS 关键字判定，
#           末尾汇总 pass/fail；有失败则以非零码退出，可直接接 CI。
set -u

TEST_DIR="${TEST_DIR:-tests}"
BUILD_DIR="${BUILD_DIR:-build}"
RTL_GLOB="rtl/*.v"
mkdir -p "$BUILD_DIR"

pass=0
fail=0
failed_cases=""

for tb in "$TEST_DIR"/*.v; do
    name=$(basename "$tb" .v)
    sim="$BUILD_DIR/$name.vvp"
    log="$BUILD_DIR/$name.log"
    echo "== [CASE] $name"

    # 第一段：编译。编不过本用例直接记 FAIL，但不退出，继续跑后面的用例
    if ! iverilog -g2012 -Wall -o "$sim" $RTL_GLOB "$tb" 2> "$log"; then
        echo "   COMPILE FAIL (see $log)"
        fail=$((fail + 1))
        failed_cases="$failed_cases $name(compile)"
        continue
    fi

    # 第二段：运行。-n 让 $finish 后直接退出，避免挂进交互模式
    vvp -n "$sim" > "$log" 2>&1
    rc=$?

    # 第三段：判定。退出码为 0 且日志有 TEST PASS 且无 TEST FAIL，才算过
    if [ "$rc" -eq 0 ] \
       && grep -q "TEST PASS" "$log" \
       && ! grep -q "TEST FAIL" "$log"; then
        echo "   PASS"
        pass=$((pass + 1))
    else
        echo "   FAIL (rc=$rc, log=$log)"
        tail -n 3 "$log" | sed 's/^/     | /'
        fail=$((fail + 1))
        failed_cases="$failed_cases $name"
    fi
done

# 第四段：汇总。退出码 0=全过，1=有用例失败（编译失败也算失败）
echo "----------------------------------------"
echo "SUMMARY: pass=$pass fail=$fail total=$((pass + fail))"
if [ "$fail" -gt 0 ]; then
    echo "FAILED CASES:$failed_cases"
    exit 1
fi
echo "ALL TESTS PASS"
exit 0
