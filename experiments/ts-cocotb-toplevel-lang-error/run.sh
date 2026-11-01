#!/usr/bin/env bash
# Reproduce TOPLEVEL_LANG / TOPLEVEL / SIM misconfiguration errors with cocotb.
# Runs every case inside the geek-eda Docker image and merges stderr into stdout.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
IMAGE="${IMAGE:-geek-eda:0.3-sta}"

docker run --rm -v "$ROOT:/work" -w /work "$IMAGE" bash -lc '
set +e
source /opt/venvs/cocotb/bin/activate
export PYTHONPATH=/work

printf "cocotb="; cocotb-config --version
python3 --version
iverilog -V | head -n 1
verilator --version | head -n 1

run_case() {
    name="$1"; shift
    printf "\n===== %s =====\n" "$name"
    printf "+ (cd cases/%s && make clean >/dev/null 2>&1; make %s)\n" "$name" "$*"
    ( cd "cases/$name" && make clean >/dev/null 2>&1 && make "$@" )
    status=$?
    printf "%s_EXIT=%d\n" "$(echo "$name" | tr "[:lower:]" "[:upper:]")" "$status"
    return "$status"
}

run_case good SIM=icarus;        good=$?
run_case nolang SIM=icarus;      nolang=$?

# A wrong language token makes Icarus SKIP the simulation, but make still exits 0.
# Capture the output so the script can assert that zero tests actually ran.
printf "\n===== badlang =====\n"
echo "+ (cd cases/badlang && make SIM=icarus)   # TOPLEVEL_LANG=vhdl"
( cd cases/badlang && make clean >/dev/null 2>&1 && make SIM=icarus ) > /tmp/badlang.log 2>&1
badlang=$?
cat /tmp/badlang.log
printf "BADLANG_EXIT=%d\n" "$badlang"
grep -q "Skipping simulation" /tmp/badlang.log && ! grep -q "TESTS=" /tmp/badlang.log
badlang_skipped=$?

printf "\n===== badspell =====\n"
echo "+ (cd cases/badspell && make SIM=icarus)  # TOPLEVEL_LANG=Verilog (wrong case)"
( cd cases/badspell && make clean >/dev/null 2>&1 && make SIM=icarus ) > /tmp/badspell.log 2>&1
badspell=$?
cat /tmp/badspell.log
printf "BADSPELL_EXIT=%d\n" "$badspell"
grep -q "Skipping simulation" /tmp/badspell.log && ! grep -q "TESTS=" /tmp/badspell.log
badspell_skipped=$?

run_case badtoplevel SIM=icarus;   badtoplevel=$?
run_case verilator SIM=verilator;  verilator_gate=$?

printf "\n===== VERILATOR-TIMING: delay compiled with --no-timing =====\n"
echo "+ verilator --no-timing --binary --top-module delay_gate delay_gate.v"
rm -rf /tmp/vlt_notiming
( cd /tmp && verilator --no-timing --binary --top-module delay_gate -Mdir vlt_notiming /work/delay_gate.v 2>&1 )
vlt_notiming=$?
printf "VLT_NOTIMING_EXIT=%d\n" "$vlt_notiming"

printf "\n===== VERILATOR-TIMING: delay compiled with timing enabled (default) =====\n"
echo "+ verilator --binary --top-module delay_gate delay_gate.v"
rm -rf /tmp/vlt_timing
( cd /tmp && verilator --binary --top-module delay_gate -Mdir vlt_timing /work/delay_gate.v 2>&1 )
vlt_timing=$?
printf "VLT_TIMING_EXIT=%d\n" "$vlt_timing"
rm -rf /tmp/vlt_notiming /tmp/vlt_timing

rc=0
[ "$good" -eq 0 ]            || { echo "ASSERT FAIL: good case must pass"; rc=1; }
[ "$nolang" -eq 0 ]          || { echo "ASSERT FAIL: omitted TOPLEVEL_LANG is auto-detected and must pass"; rc=1; }
[ "$badlang" -eq 0 ]         || { echo "ASSERT FAIL: skip path exits 0"; rc=1; }
[ "$badlang_skipped" -eq 0 ] || { echo "ASSERT FAIL: vhdl token must skip simulation with zero tests"; rc=1; }
[ "$badspell" -eq 0 ]        || { echo "ASSERT FAIL: skip path exits 0"; rc=1; }
[ "$badspell_skipped" -eq 0 ]|| { echo "ASSERT FAIL: wrong-case token must skip simulation with zero tests"; rc=1; }
[ "$badtoplevel" -ne 0 ]     || { echo "ASSERT FAIL: TOPLEVEL mismatch must fail"; rc=1; }
[ "$verilator_gate" -ne 0 ]  || { echo "ASSERT FAIL: Verilator 5.020 must be rejected"; rc=1; }
[ "$vlt_notiming" -ne 0 ]    || { echo "ASSERT FAIL: --no-timing must reject statement delay"; rc=1; }
[ "$vlt_timing" -eq 0 ]      || { echo "ASSERT FAIL: default timing support must compile the delay"; rc=1; }
printf "\nALL_ASSERTIONS=%s\n" "$( [ "$rc" -eq 0 ] && echo PASS || echo FAIL )"
exit "$rc"
'
