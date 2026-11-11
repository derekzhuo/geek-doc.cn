#!/usr/bin/env bash
set -u
STA_BIN="${STA_BIN:-sta}"
mkdir -p reports
"$STA_BIN" -version
echo "----- help report_checks -----"
echo 'help report_checks' | "$STA_BIN" -no_init 2>&1 | sed -n '/^report_checks$/,/^$/p'
echo "----- export formats -----"
"$STA_BIN" -no_init -exit export.tcl
echo "STA_EXIT=$?"
echo "===== short.rpt ====="
cat reports/short.rpt
echo "===== end.rpt ====="
cat reports/end.rpt
echo "===== summary.rpt ====="
cat reports/summary.rpt
echo "===== full_clock.rpt (head) ====="
head -20 reports/full_clock.rpt
echo "===== violators.rpt (-slack_max 0) ====="
cat reports/violators.rpt
echo "===== postprocess: VIOLATED count ====="
grep -c '(VIOLATED)' reports/full.rpt
echo "===== postprocess: worst slack ====="
grep '(VIOLATED)' reports/full.rpt | awk '{print $1}' | sort -n | head -1
echo "===== postprocess: endpoint + slack table ====="
awk '/^Endpoint/{ep=$2} /slack \(VIOLATED\)/{print ep, $1}' reports/full.rpt
