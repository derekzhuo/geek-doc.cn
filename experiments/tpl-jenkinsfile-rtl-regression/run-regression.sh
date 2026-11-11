#!/usr/bin/env bash
# run-regression.sh -- RTL 回归最小 runner 模板
# 逐用例执行 tests/<name>/run.sh，独立日志，统计 PASS/FAIL，
# 产出机器可读的 JUnit XML（results/regression.xml），有失败则非零退出。
# CI 可通过环境变量复现现场：TESTFILTER 只跑名字匹配的用例，SEED 透传给用例。
set -u

TEST_DIR="${TEST_DIR:-tests}"
LOG_DIR="${LOG_DIR:-logs}"
OUT_XML="${OUT_XML:-results/regression.xml}"
TESTFILTER="${TESTFILTER:-}"
SEED="${SEED:-1}"
JOBS_TIMEOUT="${JOBS_TIMEOUT:-300}"

mkdir -p "$LOG_DIR" "$(dirname "$OUT_XML")"
rm -f "$LOG_DIR"/*.log

# JUnit XML 文本转义（& < > "）
xml_escape() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

total=0; npass=0; nfail=0
failed_names=""
: > "$OUT_XML.tmp"

if ! compgen -G "$TEST_DIR/*/run.sh" > /dev/null; then
    echo "[REGRESS] no testcase found under $TEST_DIR/"
    exit 2
fi

for tc in "$TEST_DIR"/*/run.sh; do
    name="$(basename "$(dirname "$tc")")"
    [ -z "$TESTFILTER" ] || case "$name" in *"$TESTFILTER"*) ;; *) continue;; esac
    total=$((total + 1))
    log="$LOG_DIR/${name}.log"

    t0=$(date +%s)
    if command -v timeout > /dev/null 2>&1; then
        SEED="$SEED" timeout "$JOBS_TIMEOUT" bash "$tc" > "$log" 2>&1
    else
        SEED="$SEED" bash "$tc" > "$log" 2>&1
    fi
    rc=$?
    t1=$(date +%s); dt=$((t1 - t0))

    if [ "$rc" -eq 0 ]; then
        echo "[REGRESS] $name PASS (${dt}s)"
        npass=$((npass + 1))
        printf '    <testcase classname="rtl" name="%s" time="%s"/>\n' \
            "$name" "$dt" >> "$OUT_XML.tmp"
    else
        echo "[REGRESS] $name FAIL rc=$rc (${dt}s, log=$log)"
        nfail=$((nfail + 1))
        failed_names="$failed_names $name"
        detail="$(tail -n 20 "$log" | xml_escape)"
        {
            printf '    <testcase classname="rtl" name="%s" time="%s">\n' "$name" "$dt"
            printf '      <failure message="rc=%s">%s</failure>\n' "$rc" "$detail"
            printf '    </testcase>\n'
        } >> "$OUT_XML.tmp"
    fi
done

{
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<testsuite name="rtl-regression" tests="%s" failures="%s" seed="%s">\n' \
        "$total" "$nfail" "$SEED"
    cat "$OUT_XML.tmp"
    printf '</testsuite>\n'
} > "$OUT_XML"
rm -f "$OUT_XML.tmp"

echo "[REGRESS] SUMMARY total=$total pass=$npass fail=$nfail seed=$SEED"
if [ "$nfail" -gt 0 ]; then
    echo "[REGRESS] FAILED:$failed_names"
    exit 1
fi
echo "[REGRESS] ALL PASS"
exit 0
