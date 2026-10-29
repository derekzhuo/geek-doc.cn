#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
raw_log=".techmap-loop-raw.log"
trap 'rm -f "$raw_log"' EXIT

printf '%s\n' '=== bad: self-referential techmap template ==='
printf '%s\n' "# run: timeout -s KILL 3s yosys -p 'read_verilog top.v; hierarchy -top top; techmap -map loop_bad.v'"
# 限制失控映射的时间与地址空间，原始输出只保留统计和末尾证据。
(
    ulimit -v 262144
    timeout -s KILL 3s yosys -p 'read_verilog top.v; hierarchy -top top; techmap -map loop_bad.v'
) >"$raw_log" 2>&1
bad_rc=$?
printf '# bad-exit-code: %s\n' "$bad_rc"
printf '# bad-raw-lines: %s\n' "$(wc -l <"$raw_log")"
printf '# bad-raw-bytes: %s\n' "$(wc -c <"$raw_log")"
printf '%s\n' '--- bad raw output tail ---'
tail -n 35 "$raw_log"
printf '%s\n\n' '--- end bad raw output tail ---'

printf '%s\n' '=== fixed: map target to an explicit gate-level cell ==='
printf '%s\n' "# run: yosys -p 'read_verilog top.v; hierarchy -top top; techmap -map loop_fixed.v; stat; check'"
yosys -p 'read_verilog top.v; hierarchy -top top; techmap -map loop_fixed.v; stat; check' 2>&1
fixed_rc=$?
printf '# fixed-exit-code: %s\n' "$fixed_rc"

if [ "$bad_rc" -ne 0 ] && [ "$fixed_rc" -eq 0 ]; then
    printf 'RESULT: PASS (bad stopped with exit %s; fixed passed with exit 0)\n' "$bad_rc"
    exit 0
fi

printf 'RESULT: FAIL (bad=%s, fixed=%s; expected nonzero and 0)\n' "$bad_rc" "$fixed_rc"
exit 1
